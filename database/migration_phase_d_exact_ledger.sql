-- Additive ledger for exact inserted-row identity.
-- This does not alter or backfill legacy migration_ledger rows because their
-- original-row provenance cannot be inferred safely from natural keys alone.
CREATE TABLE IF NOT EXISTS migration_ledger_entities (
    migration_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(64) NOT NULL,
    entity_primary_key VARCHAR(255)
        CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (migration_name, table_name, entity_primary_key)
) ENGINE=InnoDB;
