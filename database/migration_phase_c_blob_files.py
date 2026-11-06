import hashlib
import json
import mimetypes
import os
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

repo_root = Path(__file__).resolve().parent.parent
backend_dir = repo_root / "backend"
for path in (repo_root, backend_dir):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

from backend.db import get_db_connection


MIGRATION_NAME = "sync_local_to_cloud"
UPLOADS_DIR = backend_dir / "uploads"
LEDGER_TABLE = "migration_ledger_entities"


def _resource_filename(resource_url):
    parsed = urlsplit(resource_url)
    if parsed.scheme or parsed.netloc or parsed.query or parsed.fragment:
        return None
    prefix = "/uploads/"
    if not parsed.path.startswith(prefix):
        return None
    filename = unquote(parsed.path[len(prefix):])
    if not filename or Path(filename).name != filename or filename.startswith("."):
        raise RuntimeError("An active resource has an unsafe local file mapping.")
    return filename


def _profile_filename(profile_photo):
    normalized = str(profile_photo).replace("\\", "/").lstrip("/")
    if normalized.startswith("profile_photos/"):
        filename = normalized
        basename = normalized[len("profile_photos/"):]
    else:
        filename = f"profile_photos/{normalized}"
        basename = normalized
    if (
        not basename
        or Path(basename).name != basename
        or basename.startswith(".")
    ):
        raise RuntimeError("A profile photo has an unsafe local file mapping.")
    return filename


def _read_mapped_file(filename):
    path = UPLOADS_DIR.joinpath(*filename.split("/"))
    try:
        resolved_path = path.resolve(strict=True)
        resolved_path.relative_to(UPLOADS_DIR.resolve())
    except (OSError, ValueError) as error:
        raise RuntimeError(
            "A mapped local file is missing or outside uploads."
        ) from error
    if not resolved_path.is_file():
        raise RuntimeError("A mapped local file is missing or outside uploads.")
    data = resolved_path.read_bytes()
    if not data:
        raise RuntimeError("A mapped local file is empty.")
    mime_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    return data, mime_type, hashlib.sha256(data).hexdigest()


def _pk_json(file_id):
    return json.dumps(
        {"file_id": int(file_id)},
        sort_keys=True,
        separators=(",", ":"),
    )


def sync_blob_files():
    connection = get_db_connection()
    cursor = None
    transaction_started = False
    try:
        cursor = connection.cursor(dictionary=True)
        connection.start_transaction(isolation_level="SERIALIZABLE")
        transaction_started = True

        cursor.execute(
            """
            SELECT COUNT(*) AS table_count
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = %s
              AND ENGINE = 'InnoDB'
            """,
            (LEDGER_TABLE,),
        )
        if cursor.fetchone()["table_count"] != 1:
            raise RuntimeError(
                "The exact-primary-key ledger is missing; apply the additive "
                "Phase D schema migration first."
            )

        cursor.execute(
            """
            SELECT resource_url
            FROM resources
            WHERE resource_url LIKE '/uploads/%'
            FOR UPDATE
            """
        )
        filenames = {
            filename
            for row in cursor.fetchall()
            if (filename := _resource_filename(row["resource_url"])) is not None
        }

        cursor.execute(
            """
            SELECT profile_photo
            FROM users
            WHERE profile_photo IS NOT NULL AND profile_photo <> ''
            FOR UPDATE
            """
        )
        filenames.update(
            _profile_filename(row["profile_photo"]) for row in cursor.fetchall()
        )

        mapped = {}
        for filename in sorted(filenames):
            data, mime_type, digest = _read_mapped_file(filename)
            mapped[filename] = (data, mime_type, digest)

        if not mapped:
            raise RuntimeError("No active resource or profile-photo files were mapped.")

        placeholders = ", ".join(["%s"] * len(mapped))
        cursor.execute(
            f"""
            SELECT file_id, filename, mime_type, file_size, SHA2(file_data, 256) AS sha256
            FROM resource_files
            WHERE filename IN ({placeholders})
            FOR UPDATE
            """,
            tuple(mapped),
        )
        existing = {row["filename"]: row for row in cursor.fetchall()}

        inserted_count = 0
        inserted_bytes = 0
        identical_count = 0
        ledger_rows = []
        for filename, (data, mime_type, digest) in mapped.items():
            row = existing.get(filename)
            if row:
                if (
                    int(row["file_size"]) != len(data)
                    or row["mime_type"] != mime_type
                    or str(row["sha256"]).lower() != digest
                ):
                    raise RuntimeError(
                        "A Cloud file conflicts with its verified local mapping; "
                        "no file was overwritten."
                    )
                identical_count += 1
                continue

            cursor.execute(
                """
                INSERT INTO resource_files
                    (filename, mime_type, file_data, file_size)
                VALUES (%s, %s, %s, %s)
                """,
                (filename, mime_type, data, len(data)),
            )
            file_id = cursor.lastrowid
            if not file_id:
                raise RuntimeError("The inserted file did not return a primary key.")
            ledger_rows.append(
                (MIGRATION_NAME, "resource_files", _pk_json(file_id))
            )
            inserted_count += 1
            inserted_bytes += len(data)

        if ledger_rows:
            cursor.executemany(
                f"""
                INSERT INTO `{LEDGER_TABLE}`
                    (migration_name, table_name, entity_primary_key)
                VALUES (%s, %s, %s)
                """,
                ledger_rows,
            )
            if cursor.rowcount != len(ledger_rows):
                raise RuntimeError("Not all exact file ledger rows were inserted.")

        connection.commit()
        transaction_started = False
        print(
            "Phase C committed: mapped=%d, inserted=%d, identical-existing=%d, "
            "inserted-bytes=%d."
            % (len(mapped), inserted_count, identical_count, inserted_bytes)
        )
    except Exception:
        if transaction_started:
            try:
                connection.rollback()
            except Exception:
                pass
        raise
    finally:
        if cursor:
            cursor.close()
        connection.close()


if __name__ == "__main__":
    try:
        sync_blob_files()
    except Exception:
        print(
            "Phase C stopped safely; no Cloud file was overwritten. "
            "Check database state before retrying."
        )
        raise
