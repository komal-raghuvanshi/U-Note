-- ====================================================================
-- U-NOTE: Consolidated Aiven Cloud (defaultdb) Schema Synchronization
-- ====================================================================
-- Safe, idempotent migration script for MySQL 8.0+ / 8.4 on Aiven.
--
-- IMPORTANT SAFETY GUARANTEES:
-- 1. Does NOT contain "USE u_note;" or hardcoded database names.
--    It operates dynamically on the currently selected DATABASE().
-- 2. Safe to rerun multiple times without errors or duplicate rows.
-- 3. Never drops, truncates, or overwrites existing user data or resources.
-- 4. Preserves all foreign key relationships and resource links.
--
-- APPROVAL NOTE:
-- This file is prepared for deployment. Do not execute against Aiven
-- production without explicit approval.
-- ====================================================================

-- --------------------------------------------------------------------
-- STEP 1: Extend `users` Table with Profile and Academic Columns
-- --------------------------------------------------------------------
SET @add_user_photo = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'profile_photo') = 0,
    'ALTER TABLE users ADD COLUMN profile_photo VARCHAR(255) NULL',
    'SELECT 1'
);
PREPARE stmt_user_photo FROM @add_user_photo;
EXECUTE stmt_user_photo;
DEALLOCATE PREPARE stmt_user_photo;

SET @add_user_branch = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'branch_id') = 0,
    'ALTER TABLE users ADD COLUMN branch_id INT NULL',
    'SELECT 1'
);
PREPARE stmt_user_branch FROM @add_user_branch;
EXECUTE stmt_user_branch;
DEALLOCATE PREPARE stmt_user_branch;

SET @add_user_semester = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'semester_id') = 0,
    'ALTER TABLE users ADD COLUMN semester_id INT NULL',
    'SELECT 1'
);
PREPARE stmt_user_semester FROM @add_user_semester;
EXECUTE stmt_user_semester;
DEALLOCATE PREPARE stmt_user_semester;

SET @add_user_branch_fk = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND CONSTRAINT_NAME = 'fk_users_branch') = 0,
    'ALTER TABLE users ADD CONSTRAINT fk_users_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)',
    'SELECT 1'
);
PREPARE stmt_user_branch_fk FROM @add_user_branch_fk;
EXECUTE stmt_user_branch_fk;
DEALLOCATE PREPARE stmt_user_branch_fk;

SET @add_user_semester_fk = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND CONSTRAINT_NAME = 'fk_users_semester') = 0,
    'ALTER TABLE users ADD CONSTRAINT fk_users_semester FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)',
    'SELECT 1'
);
PREPARE stmt_user_semester_fk FROM @add_user_semester_fk;
EXECUTE stmt_user_semester_fk;
DEALLOCATE PREPARE stmt_user_semester_fk;

-- --------------------------------------------------------------------
-- STEP 2: Create `subject_catalogue_metadata` Table
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- STEP 3: Ensure `units.unit_name` is Nullable
-- --------------------------------------------------------------------
SET @unit_name_nullable = (
    SELECT IS_NULLABLE = 'YES'
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'units'
      AND COLUMN_NAME = 'unit_name'
);

SET @modify_unit_name = IF(
    @unit_name_nullable = 0,
    'ALTER TABLE units MODIFY COLUMN unit_name VARCHAR(150) NULL',
    'SELECT 1'
);
PREPARE stmt_modify_unit_name FROM @modify_unit_name;
EXECUTE stmt_modify_unit_name;
DEALLOCATE PREPARE stmt_modify_unit_name;

-- --------------------------------------------------------------------
-- STEP 4: Extend `requests` Table with Management & Fulfillment Columns
-- --------------------------------------------------------------------
SET @add_req_title = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND COLUMN_NAME = 'request_title') = 0,
    'ALTER TABLE requests ADD COLUMN request_title VARCHAR(200) NULL',
    'SELECT 1'
);
PREPARE stmt_req_title FROM @add_req_title;
EXECUTE stmt_req_title;
DEALLOCATE PREPARE stmt_req_title;

SET @add_fulfilled_by = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND COLUMN_NAME = 'fulfilled_by') = 0,
    'ALTER TABLE requests ADD COLUMN fulfilled_by INT NULL',
    'SELECT 1'
);
PREPARE stmt_fulfilled_by FROM @add_fulfilled_by;
EXECUTE stmt_fulfilled_by;
DEALLOCATE PREPARE stmt_fulfilled_by;

SET @add_fulfilled_res = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'requests' AND COLUMN_NAME = 'fulfilled_resource_id') = 0,
    'ALTER TABLE requests ADD COLUMN fulfilled_resource_id INT NULL',
    'SELECT 1'
);
PREPARE stmt_fulfilled_res FROM @add_fulfilled_res;
EXECUTE stmt_fulfilled_res;
DEALLOCATE PREPARE stmt_fulfilled_res;

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

-- --------------------------------------------------------------------
-- STEP 5: Seed 'DS' Branch and Semesters (if missing)
-- --------------------------------------------------------------------
START TRANSACTION;

INSERT INTO branches (branch_name)
SELECT 'DS'
WHERE NOT EXISTS (
    SELECT 1 FROM branches WHERE branch_name = 'DS'
);

INSERT INTO semesters (semester_name, branch_id)
SELECT seed.semester_name, b.branch_id
FROM (
    SELECT 'Semester 1' AS semester_name UNION ALL
    SELECT 'Semester 2' UNION ALL
    SELECT 'Semester 3' UNION ALL
    SELECT 'Semester 4' UNION ALL
    SELECT 'Semester 5' UNION ALL
    SELECT 'Semester 6' UNION ALL
    SELECT 'Semester 7' UNION ALL
    SELECT 'Semester 8'
) AS seed
JOIN branches b ON b.branch_name = 'DS'
WHERE NOT EXISTS (
    SELECT 1
    FROM semesters existing
    WHERE existing.branch_id = b.branch_id
      AND existing.semester_name = seed.semester_name
);

-- --------------------------------------------------------------------
-- STEP 6: Seed AIML Curriculum Subjects (if missing)
-- --------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT seed.subject_code, seed.subject_name, sem.semester_id
FROM (
    SELECT 1 AS semester_number, 'BT-201' AS subject_code, 'Engineering Physics' AS subject_name UNION ALL
    SELECT 1, 'BT-102', 'Mathematics-I' UNION ALL
    SELECT 1, 'BT-203', 'Basic Mechanical Engineering' UNION ALL
    SELECT 1, 'BT-204', 'Basic Civil Engineering & Mechanics' UNION ALL
    SELECT 1, 'BT-205', 'Basic Computer Engineering' UNION ALL
    SELECT 2, 'BT-101', 'Engineering Chemistry' UNION ALL
    SELECT 2, 'BT-202', 'Mathematics-II' UNION ALL
    SELECT 2, 'BT-103', 'English for Communication' UNION ALL
    SELECT 2, 'BT-104', 'Basic Electrical & Electronics Engineering' UNION ALL
    SELECT 2, 'BT-105', 'Engineering Graphics' UNION ALL
    SELECT 3, 'AL-301', 'Technical Communication' UNION ALL
    SELECT 3, 'AL-302', 'Introduction to Probability and Statistics' UNION ALL
    SELECT 3, 'AL-303', 'Data Structures' UNION ALL
    SELECT 3, 'AL-304', 'Artificial Intelligence' UNION ALL
    SELECT 3, 'AL-305', 'Object Oriented Programming & Methodology' UNION ALL
    SELECT 4, 'AL-401', 'Introduction to Discrete Structure & Linear Algebra' UNION ALL
    SELECT 4, 'AL-402', 'Analysis & Design of Algorithms' UNION ALL
    SELECT 4, 'AL-403', 'Software Engineering' UNION ALL
    SELECT 4, 'AL-404', 'Computer Organization & Architecture' UNION ALL
    SELECT 4, 'AL-405', 'Machine Learning' UNION ALL
    SELECT 5, 'AL-501', 'Operating Systems' UNION ALL
    SELECT 5, 'AL-502', 'Database Management Systems' UNION ALL
    SELECT 5, 'AL-503(A)', 'Information Retrieval' UNION ALL
    SELECT 5, 'AL-504(B)', 'Natural Language Processing' UNION ALL
    SELECT 6, 'AL-601', 'Theory of Computation' UNION ALL
    SELECT 6, 'AL-602', 'Computer Networks' UNION ALL
    SELECT 6, 'AL-603(A)', 'Image and Video Processing' UNION ALL
    SELECT 6, 'AL-604(A)', 'Cloud Computing' UNION ALL
    SELECT 7, 'AL-701', 'Computer Vision' UNION ALL
    SELECT 7, 'AL-702(A)', 'AI in Gaming' UNION ALL
    SELECT 7, 'AL-702(B)', 'Advance Machine Learning' UNION ALL
    SELECT 7, 'AL-702(C)', 'Predictive Analytics' UNION ALL
    SELECT 7, 'AL-702(D)', 'Machine Learning for Data Science' UNION ALL
    SELECT 7, 'AL-703(A)', 'Compiler Design' UNION ALL
    SELECT 7, 'AL-703(B)', 'Augmented and Virtual Reality' UNION ALL
    SELECT 7, 'AL-703(C)', 'Agile Software Development' UNION ALL
    SELECT 7, 'AL-703(D)', 'Internet and Web Technology' UNION ALL
    SELECT 8, 'AL-801', 'Business Intelligence' UNION ALL
    SELECT 8, 'AL-802(A)', 'Block Chain Technologies' UNION ALL
    SELECT 8, 'AL-802(B)', 'High Performance Computing' UNION ALL
    SELECT 8, 'AL-802(C)', 'Big Data Analytics' UNION ALL
    SELECT 8, 'AL-802(D)', 'Quantum Computing' UNION ALL
    SELECT 8, 'AL-803(A)', 'Introduction to IOT' UNION ALL
    SELECT 8, 'AL-803(B)', 'Bio Informatics' UNION ALL
    SELECT 8, 'AL-803(C)', 'Managing Innovation and Entrepreneurship' UNION ALL
    SELECT 8, 'AL-803(D)', 'Human Computer Interaction'
) AS seed
JOIN branches b ON b.branch_name = 'AIML'
JOIN semesters sem
  ON sem.branch_id = b.branch_id
 AND sem.semester_name = CONCAT('Semester ', seed.semester_number)
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects existing
    WHERE existing.semester_id = sem.semester_id
      AND (
          existing.subject_code = seed.subject_code
          OR existing.subject_name = seed.subject_name
      )
);

-- --------------------------------------------------------------------
-- STEP 7: Populate `subject_catalogue_metadata`
-- --------------------------------------------------------------------
INSERT INTO subject_catalogue_metadata
    (subject_id, catalogue_code, subject_category, elective_group, is_selectable, is_provisional)
SELECT
    s.subject_id,
    seed.catalogue_code,
    seed.subject_category,
    seed.elective_group,
    1,
    seed.is_provisional
FROM (
    SELECT 1 AS semester_number, 'BT-201' AS catalogue_code, 'Engineering Physics' AS subject_name, 'Compulsory Theory' AS subject_category, NULL AS elective_group, 0 AS is_provisional UNION ALL
    SELECT 1, 'BT-102', 'Mathematics-I', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 1, 'BT-203', 'Basic Mechanical Engineering', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 1, 'BT-204', 'Basic Civil Engineering & Mechanics', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 1, 'BT-205', 'Basic Computer Engineering', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 2, 'BT-101', 'Engineering Chemistry', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 2, 'BT-202', 'Mathematics-II', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 2, 'BT-103', 'English for Communication', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 2, 'BT-104', 'Basic Electrical & Electronics Engineering', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 2, 'BT-105', 'Engineering Graphics', 'Theory Classification to Verify', NULL, 0 UNION ALL
    SELECT 3, 'AL-301', 'Technical Communication', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 3, 'AL-302', 'Introduction to Probability and Statistics', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 3, 'AL-303', 'Data Structures', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 3, 'AL-304', 'Artificial Intelligence', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 3, 'AL-305', 'Object Oriented Programming & Methodology', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 4, 'AL-401', 'Introduction to Discrete Structure & Linear Algebra', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 4, 'AL-402', 'Analysis & Design of Algorithms', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 4, 'AL-403', 'Software Engineering', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 4, 'AL-404', 'Computer Organization & Architecture', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 4, 'AL-405', 'Machine Learning', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 5, 'AL-501', 'Operating Systems', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 5, 'AL-502', 'Database Management Systems', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 5, 'AL-503(A)', 'Information Retrieval', 'Selected Departmental Elective', 'Departmental Elective', 0 UNION ALL
    SELECT 5, 'AL-504(B)', 'Natural Language Processing', 'Selected Open Elective', 'Open Elective', 0 UNION ALL
    SELECT 6, 'AL-601', 'Theory of Computation', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 6, 'AL-602', 'Computer Networks', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 6, 'AL-603(A)', 'Image and Video Processing', 'Selected Departmental Elective', 'Departmental Elective', 1 UNION ALL
    SELECT 6, 'AL-604(A)', 'Cloud Computing', 'Selected Open Elective', 'Open Elective', 0 UNION ALL
    SELECT 7, 'AL-701', 'Computer Vision', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 7, 'AL-702(A)', 'AI in Gaming', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 7, 'AL-702(B)', 'Advance Machine Learning', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 7, 'AL-702(C)', 'Predictive Analytics', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 7, 'AL-702(D)', 'Machine Learning for Data Science', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 7, 'AL-703(A)', 'Compiler Design', 'Open Elective Option', 'Open Elective', 0 UNION ALL
    SELECT 7, 'AL-703(B)', 'Augmented and Virtual Reality', 'Open Elective Option', 'Open Elective', 0 UNION ALL
    SELECT 7, 'AL-703(C)', 'Agile Software Development', 'Open Elective Option', 'Open Elective', 0 UNION ALL
    SELECT 7, 'AL-703(D)', 'Internet and Web Technology', 'Open Elective Option', 'Open Elective', 0 UNION ALL
    SELECT 8, 'AL-801', 'Business Intelligence', 'Compulsory Theory', NULL, 0 UNION ALL
    SELECT 8, 'AL-802(A)', 'Block Chain Technologies', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 8, 'AL-802(B)', 'High Performance Computing', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 8, 'AL-802(C)', 'Big Data Analytics', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 8, 'AL-802(D)', 'Quantum Computing', 'Departmental Elective Option', 'Departmental Elective', 0 UNION ALL
    SELECT 8, 'AL-803(A)', 'Introduction to IOT', 'Open Elective Option', 'Open Elective', 0 UNION ALL
    SELECT 8, 'AL-803(B)', 'Bio Informatics', 'Open Elective Option', 'Open Elective', 0 UNION ALL
    SELECT 8, 'AL-803(C)', 'Managing Innovation and Entrepreneurship', 'Open Elective Option', 'Open Elective', 0 UNION ALL
    SELECT 8, 'AL-803(D)', 'Human Computer Interaction', 'Open Elective Option', 'Open Elective', 0
) AS seed
JOIN branches b ON b.branch_name = 'AIML'
JOIN semesters sem
  ON sem.branch_id = b.branch_id
 AND sem.semester_name = CONCAT('Semester ', seed.semester_number)
JOIN subjects s
  ON s.semester_id = sem.semester_id
 AND (s.subject_code = seed.catalogue_code OR s.subject_name = seed.subject_name)
WHERE NOT EXISTS (
    SELECT 1
    FROM subject_catalogue_metadata existing_meta
    WHERE existing_meta.subject_id = s.subject_id
);

-- --------------------------------------------------------------------
-- STEP 8: Seed Units 1 through 5 for All Subjects (if missing)
-- --------------------------------------------------------------------
INSERT INTO units (subject_id, unit_number, unit_name)
SELECT s.subject_id, unit_numbers.unit_number, NULL
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) AS unit_numbers
LEFT JOIN units existing
    ON existing.subject_id = s.subject_id
   AND existing.unit_number = unit_numbers.unit_number
WHERE existing.unit_id IS NULL;

COMMIT;

-- --------------------------------------------------------------------
-- STEP 9: Post-Migration Safe Verification (Read-Only)
-- --------------------------------------------------------------------
SELECT 'Migration completed successfully' AS status;
SELECT COUNT(*) AS total_branches FROM branches;
SELECT COUNT(*) AS total_semesters FROM semesters;
SELECT COUNT(*) AS total_subjects FROM subjects;
SELECT COUNT(*) AS total_units FROM units;
SELECT COUNT(*) AS total_metadata_rows FROM subject_catalogue_metadata;
SELECT COUNT(*) AS total_resources FROM resources;
SELECT COUNT(*) AS total_requests FROM requests;
