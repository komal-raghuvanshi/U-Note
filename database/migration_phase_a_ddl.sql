-- ====================================================================
-- U-NOTE: Production Database Migration - PHASE A (DDL Schema Evolution)
-- Target: Aiven MySQL (defaultdb)
-- Safe, repeatable, idempotent schema upgrades.
-- Note: DDL triggers implicit commits in MySQL. Each statement is guarded
-- against existing columns/tables so it can be re-run safely if interrupted.
-- ====================================================================

-- 1. Extend `users` table with profile_photo (if missing)
SET @add_user_photo = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'profile_photo') = 0,
    'ALTER TABLE users ADD COLUMN profile_photo VARCHAR(255) NULL',
    'SELECT 1'
);
PREPARE stmt_user_photo FROM @add_user_photo;
EXECUTE stmt_user_photo;
DEALLOCATE PREPARE stmt_user_photo;

-- 2. Ensure `units.unit_name` is nullable (to support both named syllabi and default units)
SET @unit_nullable = (
    SELECT IS_NULLABLE = 'YES'
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'units' AND COLUMN_NAME = 'unit_name'
);
SET @alter_unit_sql = IF(@unit_nullable = 0, 'ALTER TABLE units MODIFY COLUMN unit_name VARCHAR(150) NULL', 'SELECT 1');
PREPARE stmt_alter_unit FROM @alter_unit_sql;
EXECUTE stmt_alter_unit;
DEALLOCATE PREPARE stmt_alter_unit;

-- 3. Extend `requests` table with request_title, fulfilled_by, and fulfilled_resource_id
SET @add_req_title = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND COLUMN_NAME = 'request_title') = 0,
    'ALTER TABLE requests ADD COLUMN request_title VARCHAR(200) NULL',
    'SELECT 1'
);
PREPARE stmt_req_title FROM @add_req_title;
EXECUTE stmt_req_title;
DEALLOCATE PREPARE stmt_req_title;

SET @add_req_fulfilled_by = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND COLUMN_NAME = 'fulfilled_by') = 0,
    'ALTER TABLE requests ADD COLUMN fulfilled_by INT NULL',
    'SELECT 1'
);
PREPARE stmt_req_fulfilled_by FROM @add_req_fulfilled_by;
EXECUTE stmt_req_fulfilled_by;
DEALLOCATE PREPARE stmt_req_fulfilled_by;

SET @add_req_fulfilled_res = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND COLUMN_NAME = 'fulfilled_resource_id') = 0,
    'ALTER TABLE requests ADD COLUMN fulfilled_resource_id INT NULL',
    'SELECT 1'
);
PREPARE stmt_req_fulfilled_res FROM @add_req_fulfilled_res;
EXECUTE stmt_req_fulfilled_res;
DEALLOCATE PREPARE stmt_req_fulfilled_res;

-- 4. Add foreign keys to `requests` table
SET @add_fk_fulfilled_by = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND CONSTRAINT_NAME = 'fk_requests_fulfilled_by') = 0,
    'ALTER TABLE requests ADD CONSTRAINT fk_requests_fulfilled_by FOREIGN KEY (fulfilled_by) REFERENCES users(user_id)',
    'SELECT 1'
);
PREPARE stmt_fk_fulfilled_by FROM @add_fk_fulfilled_by;
EXECUTE stmt_fk_fulfilled_by;
DEALLOCATE PREPARE stmt_fk_fulfilled_by;

SET @add_fk_fulfilled_res = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND CONSTRAINT_NAME = 'fk_requests_fulfilled_resource') = 0,
    'ALTER TABLE requests ADD CONSTRAINT fk_requests_fulfilled_resource FOREIGN KEY (fulfilled_resource_id) REFERENCES resources(resource_id) ON DELETE RESTRICT',
    'SELECT 1'
);
PREPARE stmt_fk_fulfilled_res FROM @add_fk_fulfilled_res;
EXECUTE stmt_fk_fulfilled_res;
DEALLOCATE PREPARE stmt_fk_fulfilled_res;

-- 5. Create `subject_catalogue_metadata` table
CREATE TABLE IF NOT EXISTS subject_catalogue_metadata (
    subject_id INT NOT NULL PRIMARY KEY,
    catalogue_code VARCHAR(20) NOT NULL,
    subject_category VARCHAR(80) NOT NULL,
    elective_group VARCHAR(100) NULL,
    is_selectable TINYINT(1) NOT NULL DEFAULT 1,
    is_provisional TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT subject_catalogue_metadata_subject_fk
        FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
);

-- 6. Create `resource_files` table for zero-third-party permanent BLOB file storage
CREATE TABLE IF NOT EXISTS resource_files (
    file_id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL UNIQUE,
    mime_type VARCHAR(100) NOT NULL,
    file_data LONGBLOB NOT NULL,
    file_size INT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Create `migration_ledger` table for exact tracking and non-destructive rollbacks
CREATE TABLE IF NOT EXISTS migration_ledger (
    ledger_id INT AUTO_INCREMENT PRIMARY KEY,
    migration_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    entity_natural_key VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_ledger_entry (migration_name, table_name, entity_natural_key)
);
