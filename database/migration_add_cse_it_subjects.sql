-- ============================================================================
-- U-NOTE: Academic Catalogue Migration for CSE and IT Branches
-- Target database: defaultdb (Aiven MySQL) / u_note (Local MySQL)
--
-- Description:
--   Populates full 8-semester subject catalogues for CSE and IT branches.
--   Dynamically maps semester_id via semesters + branches tables.
--   Seeds Unit 1 through Unit 5 for all subjects.
--   Completely idempotent: uses WHERE NOT EXISTS checks.
-- ============================================================================

START TRANSACTION;

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT101', 'Engineering Chemistry', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT101' OR s.subject_name = 'Engineering Chemistry')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT102', 'Mathematics-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT102' OR s.subject_name = 'Mathematics-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT103', 'English for Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT103' OR s.subject_name = 'English for Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT104', 'Basic Electrical and Electronics Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT104' OR s.subject_name = 'Basic Electrical and Electronics Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT105', 'Engineering Graphics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT105' OR s.subject_name = 'Engineering Graphics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT106', 'Manufacturing Practices', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT106' OR s.subject_name = 'Manufacturing Practices')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT107', 'Internship-I (60 Hours)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT107' OR s.subject_name = 'Internship-I (60 Hours)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT108', 'Social Internship (Rural Outreach)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT108' OR s.subject_name = 'Social Internship (Rural Outreach)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT201', 'Engineering Physics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT201' OR s.subject_name = 'Engineering Physics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT202', 'Mathematics-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT202' OR s.subject_name = 'Mathematics-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT203', 'Basic Mechanical Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT203' OR s.subject_name = 'Basic Mechanical Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT204', 'Basic Civil Engineering and Mechanics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT204' OR s.subject_name = 'Basic Civil Engineering and Mechanics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT205', 'Basic Computer Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT205' OR s.subject_name = 'Basic Computer Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT206', 'Language Lab and Seminars', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT206' OR s.subject_name = 'Language Lab and Seminars')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT101', 'Engineering Chemistry', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT101' OR s.subject_name = 'Engineering Chemistry')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT102', 'Mathematics-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT102' OR s.subject_name = 'Mathematics-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT103', 'English for Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT103' OR s.subject_name = 'English for Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT104', 'Basic Electrical and Electronics Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT104' OR s.subject_name = 'Basic Electrical and Electronics Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT105', 'Engineering Graphics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT105' OR s.subject_name = 'Engineering Graphics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT106', 'Manufacturing Practices', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT106' OR s.subject_name = 'Manufacturing Practices')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT107', 'Internship-I (60 Hours)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT107' OR s.subject_name = 'Internship-I (60 Hours)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT108', 'Social Internship (Rural Outreach)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT108' OR s.subject_name = 'Social Internship (Rural Outreach)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT201', 'Engineering Physics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT201' OR s.subject_name = 'Engineering Physics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT202', 'Mathematics-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT202' OR s.subject_name = 'Mathematics-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT203', 'Basic Mechanical Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT203' OR s.subject_name = 'Basic Mechanical Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT204', 'Basic Civil Engineering and Mechanics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT204' OR s.subject_name = 'Basic Civil Engineering and Mechanics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT205', 'Basic Computer Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT205' OR s.subject_name = 'Basic Computer Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT206', 'Language Lab and Seminars', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT206' OR s.subject_name = 'Language Lab and Seminars')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ES301', 'Energy and Environmental Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ES301' OR s.subject_name = 'Energy and Environmental Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS302', 'Discrete Structure', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS302' OR s.subject_name = 'Discrete Structure')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS303', 'Data Structure', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS303' OR s.subject_name = 'Data Structure')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS304', 'Digital Systems', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS304' OR s.subject_name = 'Digital Systems')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS305', 'Object Oriented Programming and Methodology', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS305' OR s.subject_name = 'Object Oriented Programming and Methodology')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS306', 'Computer Workshop', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS306' OR s.subject_name = 'Computer Workshop')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT107', 'Evaluation of Internship-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT107' OR s.subject_name = 'Evaluation of Internship-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT307', 'Internship-II (90 Hours, Software Based)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT307' OR s.subject_name = 'Internship-II (90 Hours, Software Based)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT308', 'Indian Constitution (Non-Credit)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT308' OR s.subject_name = 'Indian Constitution (Non-Credit)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'NC301', 'NSS/NCC', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'NC301' OR s.subject_name = 'NSS/NCC')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ES301', 'Energy and Environmental Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ES301' OR s.subject_name = 'Energy and Environmental Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT302', 'Discrete Structure', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT302' OR s.subject_name = 'Discrete Structure')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT303', 'Data Structure', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT303' OR s.subject_name = 'Data Structure')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT304', 'Object Oriented Programming and Methodology', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT304' OR s.subject_name = 'Object Oriented Programming and Methodology')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT305', 'Digital Circuits and Systems', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT305' OR s.subject_name = 'Digital Circuits and Systems')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT306', 'JAVA Programming Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT306' OR s.subject_name = 'JAVA Programming Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT107', 'Evaluation of Internship-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT107' OR s.subject_name = 'Evaluation of Internship-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT307', 'Internship-II (Software Based; duration/code to verify)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT307' OR s.subject_name = 'Internship-II (Software Based; duration/code to verify)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT308', 'Indian Constitution (Non-Credit)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT308' OR s.subject_name = 'Indian Constitution (Non-Credit)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'NC301', 'NSS/NCC', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'NC301' OR s.subject_name = 'NSS/NCC')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT401', 'Mathematics-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT401' OR s.subject_name = 'Mathematics-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS402', 'Analysis and Design of Algorithm', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS402' OR s.subject_name = 'Analysis and Design of Algorithm')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS403', 'Software Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS403' OR s.subject_name = 'Software Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS404', 'Computer Organization and Architecture', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS404' OR s.subject_name = 'Computer Organization and Architecture')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS405', 'Operating Systems', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS405' OR s.subject_name = 'Operating Systems')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS406', 'Programming Practices', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS406' OR s.subject_name = 'Programming Practices')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT407', 'Internship-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT407' OR s.subject_name = 'Internship-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT408', 'Cyber Security (Non-Credit)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT408' OR s.subject_name = 'Cyber Security (Non-Credit)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT409', 'Indian Knowledge System (Non-Credit)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT409' OR s.subject_name = 'Indian Knowledge System (Non-Credit)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'NC001', 'NSS/NCC', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'NC001' OR s.subject_name = 'NSS/NCC')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT401', 'Mathematics-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT401' OR s.subject_name = 'Mathematics-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT402', 'Computer Architecture', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT402' OR s.subject_name = 'Computer Architecture')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT403', 'Analysis and Design of Algorithm', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT403' OR s.subject_name = 'Analysis and Design of Algorithm')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT404', 'Analog and Digital Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT404' OR s.subject_name = 'Analog and Digital Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT405', 'Data Base Management System', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT405' OR s.subject_name = 'Data Base Management System')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT406', 'Introduction to MATLAB, Scilab and Web Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT406' OR s.subject_name = 'Introduction to MATLAB, Scilab and Web Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT407', 'Open Source Software Lab (Linux and R)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT407' OR s.subject_name = 'Open Source Software Lab (Linux and R)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT408', 'Internship-II (90 Hours, Software Based)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT408' OR s.subject_name = 'Internship-II (90 Hours, Software Based)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT409', 'Cyber Security (Non-Credit)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT409' OR s.subject_name = 'Cyber Security (Non-Credit)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT410', 'Indian Knowledge System (Non-Credit)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT410' OR s.subject_name = 'Indian Knowledge System (Non-Credit)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'NC001', 'NSS/NCC', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'NC001' OR s.subject_name = 'NSS/NCC')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS501', 'Theory of Computation', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS501' OR s.subject_name = 'Theory of Computation')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS502', 'Database Management Systems', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS502' OR s.subject_name = 'Database Management Systems')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS503', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS503' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS504', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS504' OR s.subject_name = 'Open Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS505', 'Lab (Linux)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS505' OR s.subject_name = 'Lab (Linux)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS506', 'Lab (Python)', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS506' OR s.subject_name = 'Lab (Python)')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS507', 'Evaluation of Internship-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS507' OR s.subject_name = 'Evaluation of Internship-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'INT-501', 'Internship-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'INT-501' OR s.subject_name = 'Internship-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS508', 'Minor Project-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS508' OR s.subject_name = 'Minor Project-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS503(A)', 'Data Analytics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS503(A)' OR s.subject_name = 'Data Analytics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS503(B)', 'Pattern Recognition', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS503(B)' OR s.subject_name = 'Pattern Recognition')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS503(C)', 'Cyber Security', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS503(C)' OR s.subject_name = 'Cyber Security')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS504(A)', 'Internet and Web Technology', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS504(A)' OR s.subject_name = 'Internet and Web Technology')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS504(B)', 'Object Oriented Programming', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS504(B)' OR s.subject_name = 'Object Oriented Programming')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS504(C)', 'Introduction to Database Management Systems', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS504(C)' OR s.subject_name = 'Introduction to Database Management Systems')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT501', 'Operating System', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT501' OR s.subject_name = 'Operating System')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT502', 'Computer Network', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT502' OR s.subject_name = 'Computer Network')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT503', 'Departmental Elective-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT503' OR s.subject_name = 'Departmental Elective-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT504', 'Open Elective-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT504' OR s.subject_name = 'Open Elective-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT505', 'Advanced Java Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT505' OR s.subject_name = 'Advanced Java Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT506', 'Soft Skills and Interpersonal Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT506' OR s.subject_name = 'Soft Skills and Interpersonal Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT407', 'Evaluation of Internship-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT407' OR s.subject_name = 'Evaluation of Internship-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'INT-501', 'Internship-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'INT-501' OR s.subject_name = 'Internship-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT508', 'Minor Project / Seminar', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT508' OR s.subject_name = 'Minor Project / Seminar')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT503(A)', 'Theory of Computation', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT503(A)' OR s.subject_name = 'Theory of Computation')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT503(B)', 'Microprocessor and Interfacing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT503(B)' OR s.subject_name = 'Microprocessor and Interfacing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT503(C)', 'Object Oriented Analysis and Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT503(C)' OR s.subject_name = 'Object Oriented Analysis and Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT504(A)', 'Artificial Intelligence', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT504(A)' OR s.subject_name = 'Artificial Intelligence')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT504(B)', 'E-Commerce and Governance', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT504(B)' OR s.subject_name = 'E-Commerce and Governance')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT504(C)', 'Java Programming', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT504(C)' OR s.subject_name = 'Java Programming')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS601', 'Machine Learning', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS601' OR s.subject_name = 'Machine Learning')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS602', 'Computer Networks', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS602' OR s.subject_name = 'Computer Networks')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS603', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS603' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS604', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS604' OR s.subject_name = 'Open Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS605', 'Data Analytics Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS605' OR s.subject_name = 'Data Analytics Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS606', 'Skill Development Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS606' OR s.subject_name = 'Skill Development Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS607', 'Internship-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS607' OR s.subject_name = 'Internship-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS608', 'Minor Project-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS608' OR s.subject_name = 'Minor Project-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS603(A)', 'Advanced Computer Architecture', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS603(A)' OR s.subject_name = 'Advanced Computer Architecture')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS603(B)', 'Computer Graphics and Visualization', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS603(B)' OR s.subject_name = 'Computer Graphics and Visualization')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS603(C)', 'Compiler Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS603(C)' OR s.subject_name = 'Compiler Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS604(A)', 'Knowledge Management', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS604(A)' OR s.subject_name = 'Knowledge Management')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS604(B)', 'Project Management', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS604(B)' OR s.subject_name = 'Project Management')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS604(C)', 'Rural Technology and Community Development', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS604(C)' OR s.subject_name = 'Rural Technology and Community Development')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT601', 'Computer Graphics and Multimedia', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT601' OR s.subject_name = 'Computer Graphics and Multimedia')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT602', 'Wireless and Mobile Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT602' OR s.subject_name = 'Wireless and Mobile Computing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT603', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT603' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT604', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT604' OR s.subject_name = 'Open Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT605', 'Programming in Python', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT605' OR s.subject_name = 'Programming in Python')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT606', 'Android Programming', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT606' OR s.subject_name = 'Android Programming')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT607', 'Internship-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT607' OR s.subject_name = 'Internship-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT608', 'Minor Project-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT608' OR s.subject_name = 'Minor Project-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT603(A)', 'Compiler Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT603(A)' OR s.subject_name = 'Compiler Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT603(B)', 'Data Mining', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT603(B)' OR s.subject_name = 'Data Mining')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT603(C)', 'Embedded Systems', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT603(C)' OR s.subject_name = 'Embedded Systems')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT604(A)', 'Intellectual Property Rights', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT604(A)' OR s.subject_name = 'Intellectual Property Rights')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT604(B)', 'Software Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT604(B)' OR s.subject_name = 'Software Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT604(C)', 'Wireless Sensor Networks', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT604(C)' OR s.subject_name = 'Wireless Sensor Networks')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS701', 'Software Architectures', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS701' OR s.subject_name = 'Software Architectures')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS702', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS702' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS703', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS703' OR s.subject_name = 'Open Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS704', 'Departmental Elective Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS704' OR s.subject_name = 'Departmental Elective Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS705', 'Open Elective Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS705' OR s.subject_name = 'Open Elective Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS706', 'Major Project-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS706' OR s.subject_name = 'Major Project-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS707', 'Evaluation of Internship-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS707' OR s.subject_name = 'Evaluation of Internship-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS702(A)', 'Computational Intelligence', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS702(A)' OR s.subject_name = 'Computational Intelligence')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS702(B)', 'Deep and Reinforcement Learning', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS702(B)' OR s.subject_name = 'Deep and Reinforcement Learning')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS702(C)', 'Wireless and Mobile Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS702(C)' OR s.subject_name = 'Wireless and Mobile Computing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS702(D)', 'Big Data', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS702(D)' OR s.subject_name = 'Big Data')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS703(A)', 'Cryptography and Information Security', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS703(A)' OR s.subject_name = 'Cryptography and Information Security')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS703(B)', 'Data Mining and Warehousing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS703(B)' OR s.subject_name = 'Data Mining and Warehousing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS703(C)', 'Agile Software Development', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS703(C)' OR s.subject_name = 'Agile Software Development')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS703(D)', 'Disaster Management', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS703(D)' OR s.subject_name = 'Disaster Management')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT701', 'Soft Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT701' OR s.subject_name = 'Soft Computing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT702', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT702' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT703', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT703' OR s.subject_name = 'Open Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT704', 'Cloud Computing Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT704' OR s.subject_name = 'Cloud Computing Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT705', 'IoT Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT705' OR s.subject_name = 'IoT Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT706', 'Major Project-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT706' OR s.subject_name = 'Major Project-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT707', 'Evaluation of Internship-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT707' OR s.subject_name = 'Evaluation of Internship-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT702(A)', 'Data Science', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT702(A)' OR s.subject_name = 'Data Science')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT702(B)', 'Cloud Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT702(B)' OR s.subject_name = 'Cloud Computing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT702(C)', 'Simulation and Modeling', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT702(C)' OR s.subject_name = 'Simulation and Modeling')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT702(D)', 'Augmented and Virtual Reality', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT702(D)' OR s.subject_name = 'Augmented and Virtual Reality')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT703(A)', 'Cyber Laws and Forensics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT703(A)' OR s.subject_name = 'Cyber Laws and Forensics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT703(B)', 'Internet of Things', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT703(B)' OR s.subject_name = 'Internet of Things')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT703(C)', 'Social Networks', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT703(C)' OR s.subject_name = 'Social Networks')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT703(D)', 'Digital Image Processing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT703(D)' OR s.subject_name = 'Digital Image Processing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS801', 'Internet of Things', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS801' OR s.subject_name = 'Internet of Things')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS802', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS802' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS803', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS803' OR s.subject_name = 'Open Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS804', 'Departmental Elective Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS804' OR s.subject_name = 'Departmental Elective Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS805', 'Major Project-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS805' OR s.subject_name = 'Major Project-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS802(A)', 'Block Chain Technologies', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS802(A)' OR s.subject_name = 'Block Chain Technologies')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS802(B)', 'Cloud Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS802(B)' OR s.subject_name = 'Cloud Computing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS802(C)', 'High Performance Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS802(C)' OR s.subject_name = 'High Performance Computing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS802(D)', 'Object Oriented Software Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS802(D)' OR s.subject_name = 'Object Oriented Software Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS803(A)', 'Image Processing and Computer Vision', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS803(A)' OR s.subject_name = 'Image Processing and Computer Vision')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS803(B)', 'Game Theory with Engineering Applications', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS803(B)' OR s.subject_name = 'Game Theory with Engineering Applications')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS803(C)', 'Internet of Things', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS803(C)' OR s.subject_name = 'Internet of Things')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'CS803(D)', 'Managing Innovation and Entrepreneurship', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'CSE'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'CS803(D)' OR s.subject_name = 'Managing Innovation and Entrepreneurship')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT801', 'Information Security', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT801' OR s.subject_name = 'Information Security')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT802', 'Departmental Elective-IV', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT802' OR s.subject_name = 'Departmental Elective-IV')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT803', 'Open Elective-IV', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT803' OR s.subject_name = 'Open Elective-IV')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT804', 'Machine Learning Lab', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT804' OR s.subject_name = 'Machine Learning Lab')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT805', 'Major Project-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT805' OR s.subject_name = 'Major Project-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT802(A)', 'Machine Learning', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT802(A)' OR s.subject_name = 'Machine Learning')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT802(B)', 'Natural Language Processing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT802(B)' OR s.subject_name = 'Natural Language Processing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT802(C)', 'Robotics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT802(C)' OR s.subject_name = 'Robotics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT802(D)', 'Quantum Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT802(D)' OR s.subject_name = 'Quantum Computing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT803(A)', 'Blockchain Technology', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT803(A)' OR s.subject_name = 'Blockchain Technology')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT803(B)', 'Human Computer Interaction', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT803(B)' OR s.subject_name = 'Human Computer Interaction')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT803(C)', '3D Printing and Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT803(C)' OR s.subject_name = '3D Printing and Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'IT803(D)', 'Parallel Computing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'IT'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'IT803(D)' OR s.subject_name = 'Parallel Computing')
  );

-- Seed Unit 1 through Unit 5 for any subject missing units
INSERT INTO units (subject_id, unit_number, unit_name)
SELECT subjects.subject_id, unit_numbers.unit_number, NULL
FROM subjects
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) AS unit_numbers
LEFT JOIN units existing
    ON existing.subject_id = subjects.subject_id
   AND existing.unit_number = unit_numbers.unit_number
WHERE existing.unit_id IS NULL;

COMMIT;
