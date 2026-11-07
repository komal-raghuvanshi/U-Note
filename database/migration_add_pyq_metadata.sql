-- ============================================================================
-- U-NOTE Database Migration: Add Exam Year and Exam Session for PYQs
-- Additive & Backward-Compatible Schema Upgrade
-- ============================================================================

START TRANSACTION;

-- 1. Add exam_year to resources table (supports years e.g. 2024, 2023, 2022)
ALTER TABLE resources ADD COLUMN IF NOT EXISTS exam_year INT NULL;

-- 2. Add exam_session to resources table (supports session e.g. 'June', 'December')
ALTER TABLE resources ADD COLUMN IF NOT EXISTS exam_session VARCHAR(20) NULL;

-- 3. Add composite index for efficient filtering by year and session
ALTER TABLE resources ADD INDEX IF NOT EXISTS idx_resources_exam (exam_year, exam_session);

COMMIT;
