-- ====================================================================
-- U-NOTE: Production Database Migration - PHASE B (DML Data Synchronization)
-- Target: Aiven MySQL (defaultdb)
-- LEGACY DML PAYLOAD: do not execute this file directly.
-- Run it only through the guarded Python runner, which owns the transaction,
-- skips the Aiven-incompatible CTAS snapshots and legacy natural-key ledger
-- statements, and writes exact inserted primary keys to
-- migration_ledger_entities. The runner refuses to run when this migration
-- already has legacy or exact ledger entries.
-- ====================================================================

START TRANSACTION;

-- --------------------------------------------------------------------
-- STEP 0: Capture Pre-Migration Snapshots (Ensures 0 Pre-Existing Records in Ledger)
-- --------------------------------------------------------------------
CREATE TEMPORARY TABLE temp_existing_branches AS
SELECT branch_name FROM branches;

CREATE TEMPORARY TABLE temp_existing_semesters AS
SELECT CONCAT(b.branch_name, ':', s.semester_name) AS natural_key
FROM semesters s JOIN branches b ON s.branch_id = b.branch_id;

CREATE TEMPORARY TABLE temp_existing_subjects AS
SELECT CONCAT(b.branch_name, ':', sem.semester_name, ':', s.subject_code) AS natural_key
FROM subjects s
JOIN semesters sem ON s.semester_id = sem.semester_id
JOIN branches b ON sem.branch_id = b.branch_id;

CREATE TEMPORARY TABLE temp_existing_metadata AS
SELECT catalogue_code FROM subject_catalogue_metadata;

CREATE TEMPORARY TABLE temp_existing_units AS
SELECT CONCAT(s.subject_code, ':Unit ', u.unit_number) AS natural_key
FROM units u JOIN subjects s ON u.subject_id = s.subject_id;

CREATE TEMPORARY TABLE temp_existing_users AS
SELECT email FROM users;

CREATE TEMPORARY TABLE temp_existing_resources AS
SELECT resource_url FROM resources;

CREATE TEMPORARY TABLE temp_existing_requests AS
SELECT CONCAT(u.email, ':', r.request_description) AS natural_key
FROM requests r JOIN users u ON r.user_id = u.user_id;

CREATE TEMPORARY TABLE temp_existing_saved AS
SELECT CONCAT(u.email, ':', r.resource_url) AS natural_key
FROM saved_resources sr JOIN users u ON sr.user_id = u.user_id JOIN resources r ON sr.resource_id = r.resource_id;

-- --------------------------------------------------------------------
-- STEP 1: Seed 'DS' Branch
-- --------------------------------------------------------------------
INSERT INTO branches (branch_name)
SELECT 'DS'
WHERE NOT EXISTS (SELECT 1 FROM branches WHERE branch_name = 'DS');

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'branches', 'DS'
FROM branches b
WHERE b.branch_name = 'DS'
  AND 'DS' NOT IN (SELECT branch_name FROM temp_existing_branches);

-- --------------------------------------------------------------------
-- STEP 2: Seed 8 Semesters for 'DS' Branch
-- --------------------------------------------------------------------
INSERT INTO semesters (semester_name, branch_id)
SELECT seed.semester_name, b.branch_id
FROM (
    SELECT 'Semester 1' AS semester_name UNION ALL SELECT 'Semester 2' UNION ALL SELECT 'Semester 3' UNION ALL SELECT 'Semester 4' UNION ALL
    SELECT 'Semester 5' UNION ALL SELECT 'Semester 6' UNION ALL SELECT 'Semester 7' UNION ALL SELECT 'Semester 8'
) AS seed
JOIN branches b ON b.branch_name = 'DS'
WHERE NOT EXISTS (
    SELECT 1 FROM semesters existing WHERE existing.branch_id = b.branch_id AND existing.semester_name = seed.semester_name
);

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'semesters', CONCAT('DS:', s.semester_name)
FROM semesters s
JOIN branches b ON s.branch_id = b.branch_id AND b.branch_name = 'DS'
WHERE CONCAT('DS:', s.semester_name) NOT IN (SELECT natural_key FROM temp_existing_semesters);

-- --------------------------------------------------------------------
-- STEP 3: Seed 44 Curriculum Subjects for AIML
-- --------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT seed.subject_code, seed.subject_name, sem.semester_id
FROM (
    -- Semester 1
    SELECT 1 AS semester_number, 'BT-201' AS subject_code, 'Engineering Physics' AS subject_name UNION ALL
    SELECT 1, 'BT-102', 'Mathematics-I' UNION ALL
    SELECT 1, 'BT-203', 'Basic Mechanical Engineering' UNION ALL
    SELECT 1, 'BT-204', 'Basic Civil Engineering & Mechanics' UNION ALL
    SELECT 1, 'BT-205', 'Basic Computer Engineering' UNION ALL
    -- Semester 2
    SELECT 2, 'BT-101', 'Engineering Chemistry' UNION ALL
    SELECT 2, 'BT-202', 'Mathematics-II' UNION ALL
    SELECT 2, 'BT-103', 'English for Communication' UNION ALL
    SELECT 2, 'BT-104', 'Basic Electrical & Electronics Engineering' UNION ALL
    SELECT 2, 'BT-105', 'Engineering Graphics' UNION ALL
    -- Semester 3
    SELECT 3, 'AL-301', 'Technical Communication' UNION ALL
    SELECT 3, 'AL-302', 'Introduction to Probability and Statistics' UNION ALL
    SELECT 3, 'AL-303', 'Data Structures' UNION ALL
    SELECT 3, 'AL-304', 'Artificial Intelligence' UNION ALL
    SELECT 3, 'AL-305', 'Object Oriented Programming & Methodology' UNION ALL
    -- Semester 4 New Curriculum Subjects
    SELECT 4, 'AL-401', 'Introduction to Discrete Structure & Linear Algebra' UNION ALL
    SELECT 4, 'AL-402', 'Analysis & Design of Algorithms' UNION ALL
    SELECT 4, 'AL-404', 'Computer Organization & Architecture' UNION ALL
    -- Semester 5
    SELECT 5, 'AL-501', 'Operating Systems' UNION ALL
    SELECT 5, 'AL-502', 'Database Management Systems' UNION ALL
    SELECT 5, 'AL-503(A)', 'Information Retrieval' UNION ALL
    SELECT 5, 'AL-504(B)', 'Natural Language Processing' UNION ALL
    -- Semester 6
    SELECT 6, 'AL-601', 'Theory of Computation' UNION ALL
    SELECT 6, 'AL-602', 'Computer Networks' UNION ALL
    SELECT 6, 'AL-603(A)', 'Image and Video Processing' UNION ALL
    SELECT 6, 'AL-604(A)', 'Cloud Computing' UNION ALL
    -- Semester 7
    SELECT 7, 'AL-701', 'Computer Vision' UNION ALL
    SELECT 7, 'AL-702(A)', 'AI in Gaming' UNION ALL
    SELECT 7, 'AL-702(B)', 'Advance Machine Learning' UNION ALL
    SELECT 7, 'AL-702(C)', 'Predictive Analytics' UNION ALL
    SELECT 7, 'AL-702(D)', 'Machine Learning for Data Science' UNION ALL
    SELECT 7, 'AL-703(A)', 'Compiler Design' UNION ALL
    SELECT 7, 'AL-703(B)', 'Augmented and Virtual Reality' UNION ALL
    SELECT 7, 'AL-703(C)', 'Agile Software Development' UNION ALL
    SELECT 7, 'AL-703(D)', 'Internet and Web Technology' UNION ALL
    -- Semester 8
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
JOIN semesters sem ON sem.branch_id = b.branch_id AND sem.semester_name = CONCAT('Semester ', seed.semester_number)
WHERE NOT EXISTS (
    SELECT 1 FROM subjects existing WHERE existing.semester_id = sem.semester_id
      AND (existing.subject_code = seed.subject_code OR existing.subject_name = seed.subject_name)
);

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'subjects', CONCAT('AIML:', sem.semester_name, ':', s.subject_code)
FROM subjects s
JOIN semesters sem ON s.semester_id = sem.semester_id
JOIN branches b ON sem.branch_id = b.branch_id AND b.branch_name = 'AIML'
WHERE CONCAT('AIML:', sem.semester_name, ':', s.subject_code) NOT IN (SELECT natural_key FROM temp_existing_subjects);

-- --------------------------------------------------------------------
-- STEP 4: Seed 47 Subject Catalogue Metadata Rows
-- --------------------------------------------------------------------
INSERT INTO subject_catalogue_metadata
    (subject_id, catalogue_code, subject_category, elective_group, is_selectable, is_provisional)
SELECT
    s.subject_id, seed.catalogue_code, seed.subject_category, seed.elective_group, seed.is_selectable, seed.is_provisional
FROM (
    -- Baseline AIML Subjects
    SELECT 4 AS semester_number, 'AIML401' AS catalogue_code, 'Artificial Intelligence' AS subject_name, 'Legacy Demo Subject' AS subject_category, NULL AS elective_group, 0 AS is_selectable, 0 AS is_provisional UNION ALL
    SELECT 4, 'AL-405', 'Machine Learning', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 4, 'AL-403', 'Software Engineering', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    -- Semester 1
    SELECT 1, 'BT-201', 'Engineering Physics', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 1, 'BT-102', 'Mathematics-I', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 1, 'BT-203', 'Basic Mechanical Engineering', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 1, 'BT-204', 'Basic Civil Engineering & Mechanics', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 1, 'BT-205', 'Basic Computer Engineering', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    -- Semester 2
    SELECT 2, 'BT-101', 'Engineering Chemistry', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 2, 'BT-202', 'Mathematics-II', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 2, 'BT-103', 'English for Communication', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 2, 'BT-104', 'Basic Electrical & Electronics Engineering', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 2, 'BT-105', 'Engineering Graphics', 'Theory Classification to Verify', NULL, 1, 0 UNION ALL
    -- Semester 3
    SELECT 3, 'AL-301', 'Technical Communication', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 3, 'AL-302', 'Introduction to Probability and Statistics', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 3, 'AL-303', 'Data Structures', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 3, 'AL-304', 'Artificial Intelligence', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 3, 'AL-305', 'Object Oriented Programming & Methodology', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    -- Semester 4 New
    SELECT 4, 'AL-401', 'Introduction to Discrete Structure & Linear Algebra', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 4, 'AL-402', 'Analysis & Design of Algorithms', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 4, 'AL-404', 'Computer Organization & Architecture', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    -- Semester 5
    SELECT 5, 'AL-501', 'Operating Systems', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 5, 'AL-502', 'Database Management Systems', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 5, 'AL-503(A)', 'Information Retrieval', 'Selected Departmental Elective', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 5, 'AL-504(B)', 'Natural Language Processing', 'Selected Open Elective', 'Open Elective', 1, 0 UNION ALL
    -- Semester 6
    SELECT 6, 'AL-601', 'Theory of Computation', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 6, 'AL-602', 'Computer Networks', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 6, 'AL-603(A)', 'Image and Video Processing', 'Selected Departmental Elective', 'Departmental Elective', 1, 1 UNION ALL
    SELECT 6, 'AL-604(A)', 'Cloud Computing', 'Selected Open Elective', 'Open Elective', 1, 0 UNION ALL
    -- Semester 7
    SELECT 7, 'AL-701', 'Computer Vision', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 7, 'AL-702(A)', 'AI in Gaming', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 7, 'AL-702(B)', 'Advance Machine Learning', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 7, 'AL-702(C)', 'Predictive Analytics', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 7, 'AL-702(D)', 'Machine Learning for Data Science', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 7, 'AL-703(A)', 'Compiler Design', 'Open Elective Option', 'Open Elective', 1, 0 UNION ALL
    SELECT 7, 'AL-703(B)', 'Augmented and Virtual Reality', 'Open Elective Option', 'Open Elective', 1, 0 UNION ALL
    SELECT 7, 'AL-703(C)', 'Agile Software Development', 'Open Elective Option', 'Open Elective', 1, 0 UNION ALL
    SELECT 7, 'AL-703(D)', 'Internet and Web Technology', 'Open Elective Option', 'Open Elective', 1, 0 UNION ALL
    -- Semester 8
    SELECT 8, 'AL-801', 'Business Intelligence', 'Compulsory Theory', NULL, 1, 0 UNION ALL
    SELECT 8, 'AL-802(A)', 'Block Chain Technologies', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 8, 'AL-802(B)', 'High Performance Computing', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 8, 'AL-802(C)', 'Big Data Analytics', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 8, 'AL-802(D)', 'Quantum Computing', 'Departmental Elective Option', 'Departmental Elective', 1, 0 UNION ALL
    SELECT 8, 'AL-803(A)', 'Introduction to IOT', 'Open Elective Option', 'Open Elective', 1, 0 UNION ALL
    SELECT 8, 'AL-803(B)', 'Bio Informatics', 'Open Elective Option', 'Open Elective', 1, 0 UNION ALL
    SELECT 8, 'AL-803(C)', 'Managing Innovation and Entrepreneurship', 'Open Elective Option', 'Open Elective', 1, 0 UNION ALL
    SELECT 8, 'AL-803(D)', 'Human Computer Interaction', 'Open Elective Option', 'Open Elective', 1, 0
) AS seed
JOIN branches b ON b.branch_name = 'AIML'
JOIN semesters sem ON sem.branch_id = b.branch_id AND sem.semester_name = CONCAT('Semester ', seed.semester_number)
JOIN subjects s ON s.semester_id = sem.semester_id AND (s.subject_code = seed.catalogue_code OR s.subject_name = seed.subject_name)
WHERE NOT EXISTS (
    SELECT 1 FROM subject_catalogue_metadata existing WHERE existing.subject_id = s.subject_id
);

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'subject_catalogue_metadata', m.catalogue_code
FROM subject_catalogue_metadata m
WHERE m.catalogue_code NOT IN (SELECT catalogue_code FROM temp_existing_metadata);

-- --------------------------------------------------------------------
-- STEP 5: Seed Units 1 through 5 (SCOPED STRICTLY TO THE 44 CURRICULUM SUBJECTS)
-- --------------------------------------------------------------------
INSERT INTO units (subject_id, unit_number, unit_name)
SELECT s.subject_id, unit_numbers.unit_number, CONCAT('Unit ', unit_numbers.unit_number)
FROM subjects s
JOIN semesters sem ON sem.semester_id = s.semester_id
JOIN branches b ON b.branch_id = sem.branch_id
CROSS JOIN (
    SELECT 1 AS unit_number UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
) AS unit_numbers
WHERE b.branch_name = 'AIML'
AND s.subject_code IN (
    'BT-201', 'BT-102', 'BT-203', 'BT-204', 'BT-205',
    'BT-101', 'BT-202', 'BT-103', 'BT-104', 'BT-105',
    'AL-301', 'AL-302', 'AL-303', 'AL-304', 'AL-305',
    'AL-401', 'AL-402', 'AL-404',
    'AL-501', 'AL-502', 'AL-503(A)', 'AL-504(B)',
    'AL-601', 'AL-602', 'AL-603(A)', 'AL-604(A)',
    'AL-701', 'AL-702(A)', 'AL-702(B)', 'AL-702(C)', 'AL-702(D)',
    'AL-703(A)', 'AL-703(B)', 'AL-703(C)', 'AL-703(D)',
    'AL-801', 'AL-802(A)', 'AL-802(B)', 'AL-802(C)', 'AL-802(D)',
    'AL-803(A)', 'AL-803(B)', 'AL-803(C)', 'AL-803(D)'
)
AND NOT EXISTS (
    SELECT 1 FROM units existing WHERE existing.subject_id = s.subject_id AND existing.unit_number = unit_numbers.unit_number
);

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'units', CONCAT(s.subject_code, ':Unit ', u.unit_number)
FROM units u
JOIN subjects s ON u.subject_id = s.subject_id
WHERE CONCAT(s.subject_code, ':Unit ', u.unit_number) NOT IN (SELECT natural_key FROM temp_existing_units);

-- The required student account must be provisioned separately. This data
-- migration never creates accounts or sets passwords.

-- --------------------------------------------------------------------
-- STEP 7: Seed Migrated Resources (12, 13, 14)
-- --------------------------------------------------------------------
INSERT INTO resources (title, resource_url, resource_type, subject_id, uploaded_by, unit_id, unit_scope, description)
SELECT 
    'unit 1',
    '/uploads/8d5188a1c2b34dea859fc1ac104db602.pdf',
    'PDF Notes',
    s.subject_id,
    u.user_id,
    NULL,
    'all',
    'Uploaded study resource for Software Engineering All Units'
FROM subjects s
JOIN semesters sem ON s.semester_id = sem.semester_id AND sem.semester_name = 'Semester 4'
JOIN branches b ON sem.branch_id = b.branch_id AND b.branch_name = 'AIML'
JOIN users u ON u.email = 'komalraghuvanshi206@gmail.com'
WHERE s.subject_name = 'Software Engineering'
  AND NOT EXISTS (SELECT 1 FROM resources WHERE resource_url = '/uploads/8d5188a1c2b34dea859fc1ac104db602.pdf');

INSERT INTO resources (title, resource_url, resource_type, subject_id, uploaded_by, unit_id, unit_scope, description)
SELECT 
    'all',
    '/uploads/71f04b4b2c7641c9b88fffa7499fffbc.png',
    'Handwritten Notes',
    s.subject_id,
    u.user_id,
    NULL,
    'all',
    'kk'
FROM subjects s
JOIN semesters sem ON s.semester_id = sem.semester_id AND sem.semester_name = 'Semester 4'
JOIN branches b ON sem.branch_id = b.branch_id AND b.branch_name = 'AIML'
JOIN users u ON u.email = 'hiteshsoni@gmail.com'
WHERE s.subject_name = 'Artificial Intelligence'
  AND NOT EXISTS (SELECT 1 FROM resources WHERE resource_url = '/uploads/71f04b4b2c7641c9b88fffa7499fffbc.png');

INSERT INTO resources (title, resource_url, resource_type, subject_id, uploaded_by, unit_id, unit_scope, description)
SELECT 
    'Resource for Analysis & Design of Algorithms',
    '/uploads/d24c2cddd4b94d76a1e6ead53ffd1e00.pdf',
    'Handwritten Notes',
    s.subject_id,
    u.user_id,
    NULL,
    'all',
    'all'
FROM subjects s
JOIN semesters sem ON s.semester_id = sem.semester_id AND sem.semester_name = 'Semester 4'
JOIN branches b ON sem.branch_id = b.branch_id AND b.branch_name = 'AIML'
JOIN users u ON u.email = 'komalraghuvanshi206@gmail.com'
WHERE s.subject_name = 'Analysis & Design of Algorithms'
  AND NOT EXISTS (SELECT 1 FROM resources WHERE resource_url = '/uploads/d24c2cddd4b94d76a1e6ead53ffd1e00.pdf');

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'resources', r.resource_url
FROM resources r
WHERE r.resource_url IN (
    '/uploads/8d5188a1c2b34dea859fc1ac104db602.pdf',
    '/uploads/71f04b4b2c7641c9b88fffa7499fffbc.png',
    '/uploads/d24c2cddd4b94d76a1e6ead53ffd1e00.pdf'
)
AND r.resource_url NOT IN (SELECT resource_url FROM temp_existing_resources);

-- --------------------------------------------------------------------
-- STEP 8: Seed Migrated Requests (6, 7)
-- --------------------------------------------------------------------
INSERT INTO requests (user_id, subject_id, unit_id, request_title, request_description, status, fulfilled_by, fulfilled_resource_id)
SELECT 
    u_req.user_id,
    s.subject_id,
    NULL,
    NULL,
    'all',
    'Fulfilled',
    u_ful.user_id,
    r.resource_id
FROM users u_req
JOIN users u_ful ON u_ful.email = 'komalraghuvanshi206@gmail.com'
JOIN subjects s ON s.subject_name = 'Analysis & Design of Algorithms'
JOIN semesters sem ON sem.semester_id = s.semester_id AND sem.semester_name = 'Semester 4'
JOIN branches b ON b.branch_id = sem.branch_id AND b.branch_name = 'AIML'
JOIN resources r ON r.resource_url = '/uploads/d24c2cddd4b94d76a1e6ead53ffd1e00.pdf'
WHERE u_req.email = 'hiteshsoni@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM requests WHERE request_description = 'all' AND user_id = u_req.user_id AND subject_id = s.subject_id
  );

INSERT INTO requests (user_id, subject_id, unit_id, request_title, request_description, status, fulfilled_by, fulfilled_resource_id)
SELECT 
    u.user_id,
    s.subject_id,
    un.unit_id,
    NULL,
    'want ass Qs of unit 2 of machin learning',
    'Pending',
    NULL,
    NULL
FROM users u
JOIN subjects s ON s.subject_name = 'Machine Learning'
JOIN semesters sem ON sem.semester_id = s.semester_id AND sem.semester_name = 'Semester 4'
JOIN branches b ON b.branch_id = sem.branch_id AND b.branch_name = 'AIML'
JOIN units un ON un.subject_id = s.subject_id AND un.unit_number = 2
WHERE u.email = 'komalraghuvanshi206@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM requests
      WHERE request_description = 'want ass Qs of unit 2 of machin learning'
        AND user_id = u.user_id
        AND subject_id = s.subject_id
        AND unit_id <=> un.unit_id
  );

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'requests', CONCAT(u.email, ':', req.request_description)
FROM requests req
JOIN users u ON req.user_id = u.user_id
WHERE CONCAT(u.email, ':', req.request_description) IN (
    'hiteshsoni@gmail.com:all',
    'komalraghuvanshi206@gmail.com:want ass Qs of unit 2 of machin learning'
)
AND CONCAT(u.email, ':', req.request_description) NOT IN (SELECT natural_key FROM temp_existing_requests);

-- --------------------------------------------------------------------
-- STEP 9: Seed Saved Resources Pair (1, 12)
-- --------------------------------------------------------------------
INSERT INTO saved_resources (user_id, resource_id)
SELECT u.user_id, r.resource_id
FROM users u
JOIN resources r ON r.resource_url = '/uploads/8d5188a1c2b34dea859fc1ac104db602.pdf'
WHERE u.email = 'komalraghuvanshi206@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM saved_resources existing WHERE existing.user_id = u.user_id AND existing.resource_id = r.resource_id
  );

-- Log ONLY if actually inserted by this migration
INSERT INTO migration_ledger (migration_name, table_name, entity_natural_key)
SELECT 'sync_local_to_cloud', 'saved_resources', CONCAT(u.email, ':', r.resource_url)
FROM saved_resources sr
JOIN users u ON sr.user_id = u.user_id
JOIN resources r ON sr.resource_id = r.resource_id
WHERE CONCAT(u.email, ':', r.resource_url) = 'komalraghuvanshi206@gmail.com:/uploads/8d5188a1c2b34dea859fc1ac104db602.pdf'
  AND CONCAT(u.email, ':', r.resource_url) NOT IN (SELECT natural_key FROM temp_existing_saved);

COMMIT;
