USE u_note;

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
ON DUPLICATE KEY UPDATE
    catalogue_code = VALUES(catalogue_code),
    subject_category = VALUES(subject_category),
    elective_group = VALUES(elective_group),
    is_selectable = VALUES(is_selectable),
    is_provisional = VALUES(is_provisional);

INSERT INTO subject_catalogue_metadata
    (subject_id, catalogue_code, subject_category, elective_group, is_selectable, is_provisional)
SELECT
    s.subject_id,
    s.subject_code,
    'Legacy Demo Subject',
    NULL,
    0,
    0
FROM subjects s
JOIN semesters sem ON sem.semester_id = s.semester_id
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'AIML'
  AND sem.semester_name = 'Semester 4'
  AND s.subject_code = 'AIML401'
  AND s.subject_name = 'Artificial Intelligence'
ON DUPLICATE KEY UPDATE
    subject_category = VALUES(subject_category),
    is_selectable = VALUES(is_selectable);

COMMIT;
