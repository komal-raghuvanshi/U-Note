import argparse
import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
SQL_PATH = ROOT_DIR / "database" / "migration_phase_b_dml.sql"
MIGRATION_NAME = "sync_local_to_cloud"
LEDGER_TABLE = "migration_ledger_entities"

TARGET_TABLES = (
    ("branches", ("branch_id",)),
    ("semesters", ("semester_id",)),
    ("subjects", ("subject_id",)),
    ("subject_catalogue_metadata", ("subject_id",)),
    ("units", ("unit_id",)),
    ("users", ("user_id",)),
    ("resources", ("resource_id",)),
    ("requests", ("request_id",)),
    ("saved_resources", ("user_id", "resource_id")),
)
TARGET_TABLE_NAMES = tuple(table for table, _ in TARGET_TABLES)


def _migration_statements():
    raw_sql = SQL_PATH.read_text(encoding="utf-8-sig")
    uncommented = "\n".join(
        line
        for line in raw_sql.splitlines()
        if not line.lstrip().startswith("--")
    )
    statements = []
    for raw_statement in uncommented.split(";"):
        statement = raw_statement.strip()
        if not statement:
            continue
        upper = statement.upper()
        if upper.startswith("CREATE TEMPORARY TABLE"):
            continue
        if upper.startswith(("START TRANSACTION", "BEGIN", "COMMIT", "ROLLBACK")):
            continue
        if upper.startswith("INSERT") and "MIGRATION_LEDGER" in upper:
            continue
        if not upper.startswith("INSERT"):
            raise RuntimeError("Phase B contains an unsupported SQL statement.")
        statements.append(statement)
    if not statements:
        raise RuntimeError("Phase B contains no data statements.")
    return statements


def _read_keys(cursor, table_name, columns, lock=False):
    quoted_columns = ", ".join(f"`{column}`" for column in columns)
    order_by = ", ".join(f"`{column}`" for column in columns)
    lock_clause = " FOR UPDATE" if lock else ""
    cursor.execute(
        f"SELECT {quoted_columns} FROM `{table_name}` "
        f"ORDER BY {order_by}{lock_clause}"
    )
    rows = cursor.fetchall()
    if len(columns) == 1:
        return {row[0] for row in rows}
    return {tuple(row) for row in rows}


def _serialize_primary_key(columns, key):
    values = (key,) if len(columns) == 1 else key
    return json.dumps(
        dict(zip(columns, values)),
        sort_keys=True,
        separators=(",", ":"),
    )


def _preflight(cursor):
    cursor.execute(
        """
        SELECT COUNT(*)
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = %s
          AND ENGINE = 'InnoDB'
        """,
        (LEDGER_TABLE,),
    )
    if cursor.fetchone()[0] != 1:
        raise RuntimeError(
            "The exact-primary-key ledger is missing; apply the additive "
            "Phase D schema migration first."
        )

    cursor.execute(
        """
        SELECT TABLE_NAME, ENGINE
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME IN (
              'branches', 'semesters', 'subjects',
              'subject_catalogue_metadata', 'units', 'users',
              'resources', 'requests', 'saved_resources'
          )
        """
    )
    engines = {table: engine for table, engine in cursor.fetchall()}
    if any(engines.get(table) != "InnoDB" for table, _ in TARGET_TABLES):
        raise RuntimeError(
            "All Phase B target tables must use InnoDB for atomic rollback."
        )

    cursor.execute(
        "SELECT COUNT(*) FROM users WHERE email = %s",
        ("hiteshsoni@gmail.com",),
    )
    if cursor.fetchone()[0] != 1:
        raise RuntimeError(
            "The required pre-existing student account is missing or ambiguous; "
            "provision accounts separately before Phase B."
        )

    cursor.execute(
        "SELECT COUNT(*) FROM migration_ledger WHERE migration_name = %s",
        (MIGRATION_NAME,),
    )
    legacy_count = cursor.fetchone()[0]
    table_placeholders = ", ".join(["%s"] * len(TARGET_TABLE_NAMES))
    cursor.execute(
        f"SELECT COUNT(*) FROM `{LEDGER_TABLE}` "
        f"WHERE migration_name = %s AND table_name IN ({table_placeholders})",
        (MIGRATION_NAME, *TARGET_TABLE_NAMES),
    )
    exact_count = cursor.fetchone()[0]
    return legacy_count, exact_count


def _assert_unapplied(cursor):
    cursor.execute(
        """
        SELECT ledger_id
        FROM migration_ledger
        WHERE migration_name = %s
        FOR UPDATE
        """,
        (MIGRATION_NAME,),
    )
    if cursor.fetchall():
        raise RuntimeError(
            "Legacy Phase B ledger rows exist. Provenance must be reconciled "
            "before any Phase B execution."
        )

    table_placeholders = ", ".join(["%s"] * len(TARGET_TABLE_NAMES))
    cursor.execute(
        f"""
        SELECT entity_primary_key
        FROM `{LEDGER_TABLE}`
        WHERE migration_name = %s
          AND table_name IN ({table_placeholders})
        FOR UPDATE
        """,
        (MIGRATION_NAME, *TARGET_TABLE_NAMES),
    )
    if cursor.fetchall():
        raise RuntimeError(
            "Exact Phase B ledger rows already exist; refusing to rerun."
        )


def _new_ledger_rows(cursor, snapshots):
    ledger_rows = []
    for table_name, columns in TARGET_TABLES:
        current_keys = _read_keys(cursor, table_name, columns)
        inserted_keys = current_keys - snapshots[table_name]
        for key in inserted_keys:
            ledger_rows.append(
                (
                    MIGRATION_NAME,
                    table_name,
                    _serialize_primary_key(columns, key),
                )
            )
    return ledger_rows


def run_phase_b(execute=False):
    from backend.db import get_db_connection

    connection = get_db_connection()
    cursor = None
    transaction_started = False
    try:
        connection.autocommit = True
        cursor = connection.cursor()
        legacy_count, exact_count = _preflight(cursor)
        print(
            "Phase B preflight: legacy ledger entries=%d; "
            "exact ledger entries=%d"
            % (legacy_count, exact_count)
        )
        if legacy_count or exact_count:
            raise RuntimeError(
                "Existing migration ledger entries make this run unsafe. "
                "Reconcile provenance before running Phase B."
            )
        if not execute:
            print("Read-only preflight only; no migration statements executed.")
            return

        connection.start_transaction(isolation_level="SERIALIZABLE")
        transaction_started = True
        _assert_unapplied(cursor)

        snapshots = {}
        for table_name, columns in TARGET_TABLES:
            snapshots[table_name] = _read_keys(
                cursor, table_name, columns, lock=True
            )

        statements = _migration_statements()
        for statement in statements:
            cursor.execute(statement)

        ledger_rows = _new_ledger_rows(cursor, snapshots)
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
                raise RuntimeError("Not all exact ledger rows were inserted.")

        connection.commit()
        transaction_started = False
        print(
            "Phase B committed atomically; exact inserted-row ledger entries=%d."
            % len(ledger_rows)
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


def main():
    parser = argparse.ArgumentParser(
        description="Inspect or run Phase B with an exact-primary-key ledger."
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="execute only after read-only preflight passes",
    )
    args = parser.parse_args()
    try:
        run_phase_b(execute=args.execute)
    except Exception:
        print(
            "Phase B stopped safely. If connection outcome is uncertain, "
            "inspect both ledgers before retrying."
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
