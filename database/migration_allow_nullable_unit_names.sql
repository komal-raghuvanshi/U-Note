-- Safe, repeatable migration. Preserves existing unit rows and relationships.
-- Run against the intended database; no table or records are created or removed.

SET @unit_name_nullable = (
    SELECT IS_NULLABLE = 'YES'
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'units'
      AND COLUMN_NAME = 'unit_name'
);

SET @unit_name_migration = IF(
    @unit_name_nullable IS NULL,
    'SELECT ''units.unit_name column not found; no changes made'' AS migration_status',
    IF(
        @unit_name_nullable = 0,
        'ALTER TABLE units MODIFY COLUMN unit_name VARCHAR(150) NULL',
        'SELECT ''units.unit_name is already nullable; no changes made'' AS migration_status'
    )
);

PREPARE unit_name_migration_stmt FROM @unit_name_migration;
EXECUTE unit_name_migration_stmt;
DEALLOCATE PREPARE unit_name_migration_stmt;
