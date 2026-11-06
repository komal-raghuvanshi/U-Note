-- U-NOTE: CSE + IT academic catalogue insert (REVIEW ONLY)
-- Corrected version: one INSERT...SELECT per catalogue row; no literal \\n sequences.
-- Target database: unote_db
--
-- Confirmed from the user's Workbench results:
--   branches: AIML=1, CSE=2, IT=3
--   semesters: semester_id 1..8 correspond to semester_number 1..8
--   subjects columns: subject_id, branch_id, semester_id, subject_name
--
-- SAFETY:
--   * Does NOT create, alter, or drop tables.
--   * Does NOT update or delete existing rows.
--   * Inserts only if the exact branch + semester + subject_name is not present.
--   * Does NOT touch AIML rows, users, resources, notes, PYQs, units, ratings, or requests.
--   * Transaction is intentionally left OPEN at the end. Review first, then choose COMMIT
--     or ROLLBACK manually. Do not close the connection before choosing.
--
-- IMPORTANT:
--   183 catalogue entries were transcribed from syllabus screenshots/details shared in chat.
--   Internship labels/codes and some semester 3-4 naming still need official-scheme verification.
--   Elective options are separate subject_name entries because subjects has no subject_code column.
--
-- This script is for review only. Do not execute until the syllabus entries are verified.

USE unote_db;

-- Preflight checks: confirm expected branch and semester IDs before any insert.
SELECT branch_id, branch_name
FROM branches
WHERE branch_id IN (1, 2, 3)
ORDER BY branch_id;

SELECT semester_id, semester_number
FROM semesters
WHERE semester_id BETWEEN 1 AND 8
ORDER BY semester_number;

START TRANSACTION;
SET @inserted_total := 0;

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT101 - Engineering Chemistry'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT101 - Engineering Chemistry'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT102 - Mathematics-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT102 - Mathematics-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT103 - English for Communication'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT103 - English for Communication'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT104 - Basic Electrical and Electronics Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT104 - Basic Electrical and Electronics Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT105 - Engineering Graphics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT105 - Engineering Graphics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT106 - Manufacturing Practices'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT106 - Manufacturing Practices'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT107 - Internship-I (60 Hours)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT107 - Internship-I (60 Hours)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 1, 'BT108 - Social Internship (Rural Outreach)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 1
      AND subject_name = 'BT108 - Social Internship (Rural Outreach)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 2, 'BT201 - Engineering Physics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 2
      AND subject_name = 'BT201 - Engineering Physics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 2, 'BT202 - Mathematics-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 2
      AND subject_name = 'BT202 - Mathematics-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 2, 'BT203 - Basic Mechanical Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 2
      AND subject_name = 'BT203 - Basic Mechanical Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 2, 'BT204 - Basic Civil Engineering and Mechanics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 2
      AND subject_name = 'BT204 - Basic Civil Engineering and Mechanics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 2, 'BT205 - Basic Computer Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 2
      AND subject_name = 'BT205 - Basic Computer Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 2, 'BT206 - Language Lab and Seminars'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 2
      AND subject_name = 'BT206 - Language Lab and Seminars'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT101 - Engineering Chemistry'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT101 - Engineering Chemistry'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT102 - Mathematics-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT102 - Mathematics-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT103 - English for Communication'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT103 - English for Communication'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT104 - Basic Electrical and Electronics Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT104 - Basic Electrical and Electronics Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT105 - Engineering Graphics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT105 - Engineering Graphics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT106 - Manufacturing Practices'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT106 - Manufacturing Practices'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT107 - Internship-I (60 Hours)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT107 - Internship-I (60 Hours)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 1, 'BT108 - Social Internship (Rural Outreach)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 1
      AND subject_name = 'BT108 - Social Internship (Rural Outreach)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 2, 'BT201 - Engineering Physics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 2
      AND subject_name = 'BT201 - Engineering Physics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 2, 'BT202 - Mathematics-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 2
      AND subject_name = 'BT202 - Mathematics-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 2, 'BT203 - Basic Mechanical Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 2
      AND subject_name = 'BT203 - Basic Mechanical Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 2, 'BT204 - Basic Civil Engineering and Mechanics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 2
      AND subject_name = 'BT204 - Basic Civil Engineering and Mechanics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 2, 'BT205 - Basic Computer Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 2
      AND subject_name = 'BT205 - Basic Computer Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 2, 'BT206 - Language Lab and Seminars'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 2
      AND subject_name = 'BT206 - Language Lab and Seminars'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'ES301 - Energy and Environmental Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'ES301 - Energy and Environmental Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'CS302 - Discrete Structure'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'CS302 - Discrete Structure'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'CS303 - Data Structure'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'CS303 - Data Structure'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'CS304 - Digital Systems'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'CS304 - Digital Systems'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'CS305 - Object Oriented Programming and Methodology'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'CS305 - Object Oriented Programming and Methodology'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'CS306 - Computer Workshop'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'CS306 - Computer Workshop'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'BT107 - Evaluation of Internship-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'BT107 - Evaluation of Internship-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'BT307 - Internship-II (90 Hours, Software Based)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'BT307 - Internship-II (90 Hours, Software Based)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'BT308 - Indian Constitution (Non-Credit)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'BT308 - Indian Constitution (Non-Credit)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 3, 'NC301 - NSS/NCC'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 3
      AND subject_name = 'NC301 - NSS/NCC'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'ES301 - Energy and Environmental Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'ES301 - Energy and Environmental Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'IT302 - Discrete Structure'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'IT302 - Discrete Structure'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'IT303 - Data Structure'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'IT303 - Data Structure'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'IT304 - Object Oriented Programming and Methodology'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'IT304 - Object Oriented Programming and Methodology'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'IT305 - Digital Circuits and Systems'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'IT305 - Digital Circuits and Systems'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'IT306 - JAVA Programming Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'IT306 - JAVA Programming Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'BT107 - Evaluation of Internship-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'BT107 - Evaluation of Internship-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'BT307 - Internship-II (Software Based; duration/code to verify)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'BT307 - Internship-II (Software Based; duration/code to verify)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'BT308 - Indian Constitution (Non-Credit)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'BT308 - Indian Constitution (Non-Credit)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 3, 'NC301 - NSS/NCC'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 3
      AND subject_name = 'NC301 - NSS/NCC'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'BT401 - Mathematics-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'BT401 - Mathematics-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'CS402 - Analysis and Design of Algorithm'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'CS402 - Analysis and Design of Algorithm'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'CS403 - Software Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'CS403 - Software Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'CS404 - Computer Organization and Architecture'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'CS404 - Computer Organization and Architecture'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'CS405 - Operating Systems'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'CS405 - Operating Systems'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'CS406 - Programming Practices'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'CS406 - Programming Practices'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'BT407 - Internship-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'BT407 - Internship-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'BT408 - Cyber Security (Non-Credit)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'BT408 - Cyber Security (Non-Credit)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'BT409 - Indian Knowledge System (Non-Credit)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'BT409 - Indian Knowledge System (Non-Credit)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 4, 'NC001 - NSS/NCC'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 4
      AND subject_name = 'NC001 - NSS/NCC'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'BT401 - Mathematics-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'BT401 - Mathematics-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'IT402 - Computer Architecture'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'IT402 - Computer Architecture'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'IT403 - Analysis and Design of Algorithm'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'IT403 - Analysis and Design of Algorithm'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'IT404 - Analog and Digital Communication'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'IT404 - Analog and Digital Communication'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'IT405 - Data Base Management System'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'IT405 - Data Base Management System'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'IT406 - Introduction to MATLAB, Scilab and Web Design'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'IT406 - Introduction to MATLAB, Scilab and Web Design'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'IT407 - Open Source Software Lab (Linux and R)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'IT407 - Open Source Software Lab (Linux and R)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'BT408 - Internship-II (90 Hours, Software Based)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'BT408 - Internship-II (90 Hours, Software Based)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'BT409 - Cyber Security (Non-Credit)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'BT409 - Cyber Security (Non-Credit)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'BT410 - Indian Knowledge System (Non-Credit)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'BT410 - Indian Knowledge System (Non-Credit)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 4, 'NC001 - NSS/NCC'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 4
      AND subject_name = 'NC001 - NSS/NCC'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS501 - Theory of Computation'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS501 - Theory of Computation'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS502 - Database Management Systems'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS502 - Database Management Systems'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS503 - Departmental Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS503 - Departmental Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS504 - Open Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS504 - Open Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS505 - Lab (Linux)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS505 - Lab (Linux)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS506 - Lab (Python)'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS506 - Lab (Python)'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS507 - Evaluation of Internship-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS507 - Evaluation of Internship-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'Internship-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'Internship-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS508 - Minor Project-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS508 - Minor Project-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS503(A) - Data Analytics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS503(A) - Data Analytics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS503(B) - Pattern Recognition'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS503(B) - Pattern Recognition'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS503(C) - Cyber Security'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS503(C) - Cyber Security'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS504(A) - Internet and Web Technology'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS504(A) - Internet and Web Technology'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS504(B) - Object Oriented Programming'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS504(B) - Object Oriented Programming'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 5, 'CS504(C) - Introduction to Database Management Systems'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 5
      AND subject_name = 'CS504(C) - Introduction to Database Management Systems'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT501 - Operating System'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT501 - Operating System'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT502 - Computer Network'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT502 - Computer Network'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT503 - Departmental Elective-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT503 - Departmental Elective-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT504 - Open Elective-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT504 - Open Elective-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT505 - Advanced Java Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT505 - Advanced Java Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT506 - Soft Skills and Interpersonal Communication'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT506 - Soft Skills and Interpersonal Communication'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'BT407 - Evaluation of Internship-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'BT407 - Evaluation of Internship-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'Internship-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'Internship-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT508 - Minor Project / Seminar'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT508 - Minor Project / Seminar'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT503(A) - Theory of Computation'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT503(A) - Theory of Computation'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT503(B) - Microprocessor and Interfacing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT503(B) - Microprocessor and Interfacing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT503(C) - Object Oriented Analysis and Design'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT503(C) - Object Oriented Analysis and Design'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT504(A) - Artificial Intelligence'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT504(A) - Artificial Intelligence'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT504(B) - E-Commerce and Governance'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT504(B) - E-Commerce and Governance'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 5, 'IT504(C) - Java Programming'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 5
      AND subject_name = 'IT504(C) - Java Programming'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS601 - Machine Learning'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS601 - Machine Learning'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS602 - Computer Networks'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS602 - Computer Networks'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS603 - Departmental Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS603 - Departmental Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS604 - Open Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS604 - Open Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS605 - Data Analytics Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS605 - Data Analytics Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS606 - Skill Development Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS606 - Skill Development Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS607 - Internship-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS607 - Internship-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS608 - Minor Project-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS608 - Minor Project-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS603(A) - Advanced Computer Architecture'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS603(A) - Advanced Computer Architecture'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS603(B) - Computer Graphics and Visualization'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS603(B) - Computer Graphics and Visualization'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS603(C) - Compiler Design'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS603(C) - Compiler Design'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS604(A) - Knowledge Management'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS604(A) - Knowledge Management'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS604(B) - Project Management'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS604(B) - Project Management'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 6, 'CS604(C) - Rural Technology and Community Development'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 6
      AND subject_name = 'CS604(C) - Rural Technology and Community Development'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT601 - Computer Graphics and Multimedia'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT601 - Computer Graphics and Multimedia'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT602 - Wireless and Mobile Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT602 - Wireless and Mobile Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT603 - Departmental Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT603 - Departmental Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT604 - Open Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT604 - Open Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT605 - Programming in Python'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT605 - Programming in Python'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT606 - Android Programming'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT606 - Android Programming'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT607 - Internship-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT607 - Internship-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT608 - Minor Project-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT608 - Minor Project-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT603(A) - Compiler Design'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT603(A) - Compiler Design'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT603(B) - Data Mining'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT603(B) - Data Mining'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT603(C) - Embedded Systems'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT603(C) - Embedded Systems'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT604(A) - Intellectual Property Rights'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT604(A) - Intellectual Property Rights'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT604(B) - Software Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT604(B) - Software Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 6, 'IT604(C) - Wireless Sensor Networks'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 6
      AND subject_name = 'IT604(C) - Wireless Sensor Networks'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS701 - Software Architectures'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS701 - Software Architectures'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS702 - Departmental Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS702 - Departmental Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS703 - Open Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS703 - Open Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS704 - Departmental Elective Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS704 - Departmental Elective Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS705 - Open Elective Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS705 - Open Elective Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS706 - Major Project-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS706 - Major Project-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS707 - Evaluation of Internship-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS707 - Evaluation of Internship-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS702(A) - Computational Intelligence'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS702(A) - Computational Intelligence'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS702(B) - Deep and Reinforcement Learning'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS702(B) - Deep and Reinforcement Learning'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS702(C) - Wireless and Mobile Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS702(C) - Wireless and Mobile Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS702(D) - Big Data'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS702(D) - Big Data'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS703(A) - Cryptography and Information Security'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS703(A) - Cryptography and Information Security'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS703(B) - Data Mining and Warehousing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS703(B) - Data Mining and Warehousing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS703(C) - Agile Software Development'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS703(C) - Agile Software Development'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 7, 'CS703(D) - Disaster Management'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 7
      AND subject_name = 'CS703(D) - Disaster Management'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT701 - Soft Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT701 - Soft Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT702 - Departmental Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT702 - Departmental Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT703 - Open Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT703 - Open Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT704 - Cloud Computing Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT704 - Cloud Computing Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT705 - IoT Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT705 - IoT Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT706 - Major Project-I'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT706 - Major Project-I'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT707 - Evaluation of Internship-III'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT707 - Evaluation of Internship-III'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT702(A) - Data Science'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT702(A) - Data Science'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT702(B) - Cloud Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT702(B) - Cloud Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT702(C) - Simulation and Modeling'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT702(C) - Simulation and Modeling'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT702(D) - Augmented and Virtual Reality'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT702(D) - Augmented and Virtual Reality'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT703(A) - Cyber Laws and Forensics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT703(A) - Cyber Laws and Forensics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT703(B) - Internet of Things'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT703(B) - Internet of Things'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT703(C) - Social Networks'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT703(C) - Social Networks'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 7, 'IT703(D) - Digital Image Processing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 7
      AND subject_name = 'IT703(D) - Digital Image Processing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS801 - Internet of Things'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS801 - Internet of Things'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS802 - Departmental Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS802 - Departmental Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS803 - Open Elective'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS803 - Open Elective'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS804 - Departmental Elective Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS804 - Departmental Elective Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS805 - Major Project-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS805 - Major Project-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS802(A) - Block Chain Technologies'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS802(A) - Block Chain Technologies'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS802(B) - Cloud Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS802(B) - Cloud Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS802(C) - High Performance Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS802(C) - High Performance Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS802(D) - Object Oriented Software Engineering'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS802(D) - Object Oriented Software Engineering'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS803(A) - Image Processing and Computer Vision'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS803(A) - Image Processing and Computer Vision'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS803(B) - Game Theory with Engineering Applications'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS803(B) - Game Theory with Engineering Applications'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS803(C) - Internet of Things'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS803(C) - Internet of Things'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 2, 8, 'CS803(D) - Managing Innovation and Entrepreneurship'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 2
      AND semester_id = 8
      AND subject_name = 'CS803(D) - Managing Innovation and Entrepreneurship'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT801 - Information Security'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT801 - Information Security'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT802 - Departmental Elective-IV'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT802 - Departmental Elective-IV'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT803 - Open Elective-IV'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT803 - Open Elective-IV'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT804 - Machine Learning Lab'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT804 - Machine Learning Lab'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT805 - Major Project-II'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT805 - Major Project-II'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT802(A) - Machine Learning'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT802(A) - Machine Learning'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT802(B) - Natural Language Processing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT802(B) - Natural Language Processing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT802(C) - Robotics'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT802(C) - Robotics'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT802(D) - Quantum Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT802(D) - Quantum Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT803(A) - Blockchain Technology'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT803(A) - Blockchain Technology'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT803(B) - Human Computer Interaction'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT803(B) - Human Computer Interaction'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT803(C) - 3D Printing and Design'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT803(C) - 3D Printing and Design'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

INSERT INTO subjects (branch_id, semester_id, subject_name)
SELECT 3, 8, 'IT803(D) - Parallel Computing'
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects
    WHERE branch_id = 3
      AND semester_id = 8
      AND subject_name = 'IT803(D) - Parallel Computing'
);
SET @inserted_total := @inserted_total + ROW_COUNT();

-- Number of rows newly inserted by this script:
SELECT @inserted_total AS rows_inserted_by_this_script;

-- Review CSE + IT catalogue:
SELECT
    b.branch_name,
    s.semester_number,
    sub.subject_name
FROM subjects AS sub
JOIN branches AS b ON b.branch_id = sub.branch_id
JOIN semesters AS s ON s.semester_id = sub.semester_id
WHERE b.branch_name IN ('CSE', 'IT')
ORDER BY b.branch_name, s.semester_number, sub.subject_name;

-- IMPORTANT: choose ONE command manually only after reviewing:
-- COMMIT;
-- ROLLBACK;
