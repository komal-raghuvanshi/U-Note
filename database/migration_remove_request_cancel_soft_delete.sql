-- Remove request cancellation and soft-delete schema support.
-- Run only after request rows with unsupported statuses have been removed.
-- This migration never deletes request, resource, or user rows and is safe to rerun.

USE u_note;

SET @add_supported_status_check = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND CONSTRAINT_NAME = 'chk_requests_status_supported'
       AND CONSTRAINT_TYPE = 'CHECK') = 0,
    'ALTER TABLE requests ADD CONSTRAINT chk_requests_status_supported CHECK (status IN (''Pending'', ''Fulfilled'', ''Rejected''))',
    'SELECT 1'
);
PREPARE add_supported_status_check_stmt FROM @add_supported_status_check;
EXECUTE add_supported_status_check_stmt;
DEALLOCATE PREPARE add_supported_status_check_stmt;

SET @drop_legacy_status_check = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND CONSTRAINT_NAME = 'chk_requests_status'
       AND CONSTRAINT_TYPE = 'CHECK') > 0,
    'ALTER TABLE requests DROP CHECK chk_requests_status',
    'SELECT 1'
);
PREPARE drop_legacy_status_check_stmt FROM @drop_legacy_status_check;
EXECUTE drop_legacy_status_check_stmt;
DEALLOCATE PREPARE drop_legacy_status_check_stmt;

SET @add_final_status_check = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND CONSTRAINT_NAME = 'chk_requests_status'
       AND CONSTRAINT_TYPE = 'CHECK') = 0,
    'ALTER TABLE requests ADD CONSTRAINT chk_requests_status CHECK (status IN (''Pending'', ''Fulfilled'', ''Rejected''))',
    'SELECT 1'
);
PREPARE add_final_status_check_stmt FROM @add_final_status_check;
EXECUTE add_final_status_check_stmt;
DEALLOCATE PREPARE add_final_status_check_stmt;

SET @drop_supported_status_check = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND CONSTRAINT_NAME = 'chk_requests_status_supported'
       AND CONSTRAINT_TYPE = 'CHECK') > 0,
    'ALTER TABLE requests DROP CHECK chk_requests_status_supported',
    'SELECT 1'
);
PREPARE drop_supported_status_check_stmt FROM @drop_supported_status_check;
EXECUTE drop_supported_status_check_stmt;
DEALLOCATE PREPARE drop_supported_status_check_stmt;

SET @drop_deleted_by_fk = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND CONSTRAINT_NAME = 'fk_requests_deleted_by'
       AND CONSTRAINT_TYPE = 'FOREIGN KEY') > 0,
    'ALTER TABLE requests DROP FOREIGN KEY fk_requests_deleted_by',
    'SELECT 1'
);
PREPARE drop_deleted_by_fk_stmt FROM @drop_deleted_by_fk;
EXECUTE drop_deleted_by_fk_stmt;
DEALLOCATE PREPARE drop_deleted_by_fk_stmt;

SET @drop_deleted_at_index = IF(
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND INDEX_NAME = 'idx_requests_deleted_at') > 0,
    'ALTER TABLE requests DROP INDEX idx_requests_deleted_at',
    'SELECT 1'
);
PREPARE drop_deleted_at_index_stmt FROM @drop_deleted_at_index;
EXECUTE drop_deleted_at_index_stmt;
DEALLOCATE PREPARE drop_deleted_at_index_stmt;

SET @drop_deleted_by_column = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND COLUMN_NAME = 'deleted_by') > 0,
    'ALTER TABLE requests DROP COLUMN deleted_by',
    'SELECT 1'
);
PREPARE drop_deleted_by_column_stmt FROM @drop_deleted_by_column;
EXECUTE drop_deleted_by_column_stmt;
DEALLOCATE PREPARE drop_deleted_by_column_stmt;

SET @drop_deleted_at_column = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND COLUMN_NAME = 'deleted_at') > 0,
    'ALTER TABLE requests DROP COLUMN deleted_at',
    'SELECT 1'
);
PREPARE drop_deleted_at_column_stmt FROM @drop_deleted_at_column;
EXECUTE drop_deleted_at_column_stmt;
DEALLOCATE PREPARE drop_deleted_at_column_stmt;
