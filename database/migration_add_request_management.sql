-- Add request titles without changing existing request rows.
-- Safe to rerun against the existing u_note database.

USE u_note;

SET @add_request_title = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND COLUMN_NAME = 'request_title') = 0,
    'ALTER TABLE requests ADD COLUMN request_title VARCHAR(200) NULL',
    'SELECT 1'
);
PREPARE add_request_title_stmt FROM @add_request_title;
EXECUTE add_request_title_stmt;
DEALLOCATE PREPARE add_request_title_stmt;

SET @existing_status_check = (
    SELECT tc.CONSTRAINT_NAME
    FROM information_schema.TABLE_CONSTRAINTS tc
    JOIN information_schema.CHECK_CONSTRAINTS cc
      ON cc.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
     AND cc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
    WHERE tc.CONSTRAINT_SCHEMA = DATABASE()
      AND tc.TABLE_NAME = 'requests'
      AND tc.CONSTRAINT_TYPE = 'CHECK'
      AND tc.CONSTRAINT_NAME <> 'chk_requests_status'
      AND cc.CHECK_CLAUSE LIKE '%status%'
    LIMIT 1
);
SET @drop_status_check = IF(
    @existing_status_check IS NOT NULL,
    CONCAT(
        'ALTER TABLE requests DROP CHECK `',
        REPLACE(@existing_status_check, '`', '``'),
        '`'
    ),
    'SELECT 1'
);
PREPARE drop_status_check_stmt FROM @drop_status_check;
EXECUTE drop_status_check_stmt;
DEALLOCATE PREPARE drop_status_check_stmt;

SET @add_status_check = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND TABLE_NAME = 'requests'
       AND CONSTRAINT_NAME = 'chk_requests_status'
       AND CONSTRAINT_TYPE = 'CHECK') = 0,
    'ALTER TABLE requests ADD CONSTRAINT chk_requests_status CHECK (status IN (''Pending'', ''Fulfilled'', ''Rejected''))',
    'SELECT 1'
);
PREPARE add_status_check_stmt FROM @add_status_check;
EXECUTE add_status_check_stmt;
DEALLOCATE PREPARE add_status_check_stmt;
