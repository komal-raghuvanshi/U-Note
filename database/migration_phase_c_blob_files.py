# ====================================================================
# U-NOTE: Production Database Migration - PHASE C (BLOB Files Sync)
# Target: Aiven MySQL (defaultdb)
# Populates `resource_files` table with permanent binary data.
# Zero third-party APIs. Preserves full file availability across Vercel redeployments.
# ====================================================================

import os
import sys
import mimetypes

# Add repo root and backend to sys.path
repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
backend_dir = os.path.join(repo_root, "backend")
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from backend.db import get_db_connection


def sync_blob_files():
    conn = get_db_connection()
    cur = conn.cursor()

    uploads_dir = os.path.join(backend_dir, "uploads")
    synced_files = []

    # 1. Sync study resources
    if os.path.isdir(uploads_dir):
        for fname in sorted(os.listdir(uploads_dir)):
            fpath = os.path.join(uploads_dir, fname)
            if os.path.isfile(fpath) and not fname.startswith("."):
                mime, _ = mimetypes.guess_type(fname)
                mime = mime or "application/octet-stream"
                with open(fpath, "rb") as f:
                    data = f.read()
                cur.execute(
                    """
                    INSERT INTO resource_files (filename, mime_type, file_data, file_size)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        mime_type = VALUES(mime_type),
                        file_data = VALUES(file_data),
                        file_size = VALUES(file_size)
                    """,
                    (fname, mime, data, len(data)),
                )
                cur.execute(
                    """
                    INSERT IGNORE INTO migration_ledger (migration_name, table_name, entity_natural_key)
                    VALUES ('sync_local_to_cloud', 'resource_files', %s)
                    """,
                    (fname,),
                )
                synced_files.append((fname, len(data), mime))

    # 2. Sync profile photos
    profile_dir = os.path.join(uploads_dir, "profile_photos")
    if os.path.isdir(profile_dir):
        for fname in sorted(os.listdir(profile_dir)):
            fpath = os.path.join(profile_dir, fname)
            if os.path.isfile(fpath) and not fname.startswith("."):
                mime, _ = mimetypes.guess_type(fname)
                mime = mime or "image/jpeg"
                with open(fpath, "rb") as f:
                    data = f.read()
                key = f"profile_photos/{fname}"
                cur.execute(
                    """
                    INSERT INTO resource_files (filename, mime_type, file_data, file_size)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        mime_type = VALUES(mime_type),
                        file_data = VALUES(file_data),
                        file_size = VALUES(file_size)
                    """,
                    (key, mime, data, len(data)),
                )
                cur.execute(
                    """
                    INSERT IGNORE INTO migration_ledger (migration_name, table_name, entity_natural_key)
                    VALUES ('sync_local_to_cloud', 'resource_files', %s)
                    """,
                    (key,),
                )
                synced_files.append((key, len(data), mime))

    conn.commit()
    cur.close()
    conn.close()

    total_bytes = sum(f[1] for f in synced_files)
    print(f"Successfully synced {len(synced_files)} files into resource_files ({total_bytes / (1024*1024):.2f} MB)")
    for f in synced_files:
        print(f"  - {f[0]} ({f[1]:,} bytes, {f[2]})")


if __name__ == "__main__":
    sync_blob_files()
