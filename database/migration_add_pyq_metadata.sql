-- ============================================================================
-- U-NOTE Database Migration: Add Exam Year and Exam Session for PYQs
-- Additive & Backward-Compatible Schema Upgrade
-- Compatible with all MySQL 8.0+ versions
-- ============================================================================

-- 1. Add exam_year to resources table (if missing)
SET @add_exam_year = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'resources' AND COLUMN_NAME = 'exam_year') = 0,
    'ALTER TABLE resources ADD COLUMN exam_year INT NULL',
    'SELECT 1'
);
PREPARE stmt_exam_year FROM @add_exam_year;
EXECUTE stmt_exam_year;
DEALLOCATE PREPARE stmt_exam_year;

-- 2. Add exam_session to resources table (if missing)
SET @add_exam_session = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'resources' AND COLUMN_NAME = 'exam_session') = 0,
    'ALTER TABLE resources ADD COLUMN exam_session VARCHAR(20) NULL',
    'SELECT 1'
);
PREPARE stmt_exam_session FROM @add_exam_session;
EXECUTE stmt_exam_session;
DEALLOCATE PREPARE stmt_exam_session;

-- 3. Add composite index idx_resources_exam (if missing)
SET @add_idx_exam = IF(
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'resources' AND INDEX_NAME = 'idx_resources_exam') = 0,
    'ALTER TABLE resources ADD INDEX idx_resources_exam (exam_year, exam_session)',
    'SELECT 1'
);
PREPARE stmt_idx_exam FROM @add_idx_exam;
EXECUTE stmt_idx_exam;
DEALLOCATE PREPARE stmt_idx_exam;
