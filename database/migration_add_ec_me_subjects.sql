-- ============================================================================
-- U-NOTE: Academic Catalogue Migration for EC and ME Branches
-- Target database: defaultdb (Aiven MySQL) / u_note (Local MySQL)
--
-- Description:
--   Populates full 8-semester subject catalogues for EC and ME branches.
--   Dynamically maps semester_id via semesters + branches tables.
--   Seeds Unit 1 through Unit 5 for all subjects.
--   Completely idempotent: uses WHERE NOT EXISTS checks.
-- ============================================================================

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 1
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT102', 'Mathematics-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT102' OR s.subject_name = 'Mathematics-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT201', 'Engineering Physics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT201' OR s.subject_name = 'Engineering Physics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT203', 'Basic Mechanical Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT203' OR s.subject_name = 'Basic Mechanical Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT204', 'Basic Civil Engineering & Mechanics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT204' OR s.subject_name = 'Basic Civil Engineering & Mechanics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT205', 'Basic Computer Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT205' OR s.subject_name = 'Basic Computer Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT206', 'Language Lab & Seminars', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT206' OR s.subject_name = 'Language Lab & Seminars')
  );

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 2
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT101', 'Engineering Chemistry', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT101' OR s.subject_name = 'Engineering Chemistry')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT103', 'English for Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT103' OR s.subject_name = 'English for Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT104', 'Basic Electrical & Electronics Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT104' OR s.subject_name = 'Basic Electrical & Electronics Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT105', 'Engineering Graphics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT105' OR s.subject_name = 'Engineering Graphics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT202', 'Mathematics-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT202' OR s.subject_name = 'Mathematics-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT106', 'Manufacturing Practices', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT106' OR s.subject_name = 'Manufacturing Practices')
  );

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 3
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT301', 'Mathematics-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT301' OR s.subject_name = 'Mathematics-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC302', 'Electronic Measurement & Instrumentation', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC302' OR s.subject_name = 'Electronic Measurement & Instrumentation')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC303', 'Digital System Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC303' OR s.subject_name = 'Digital System Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC304', 'Electronic Devices', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC304' OR s.subject_name = 'Electronic Devices')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC305', 'Network Analysis', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC305' OR s.subject_name = 'Network Analysis')
  );

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 4
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ES401', 'Energy & Environmental Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ES401' OR s.subject_name = 'Energy & Environmental Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC402', 'Signals & Systems', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC402' OR s.subject_name = 'Signals & Systems')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC403', 'Analog Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC403' OR s.subject_name = 'Analog Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC404', 'Control System', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC404' OR s.subject_name = 'Control System')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC405', 'Analog Circuits', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC405' OR s.subject_name = 'Analog Circuits')
  );

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 5
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC501', 'Microprocessor & its Application', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC501' OR s.subject_name = 'Microprocessor & its Application')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC502', 'Digital Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC502' OR s.subject_name = 'Digital Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC503', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC503' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC504', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC504' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 6
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC601', 'Digital Signal Processing', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC601' OR s.subject_name = 'Digital Signal Processing')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC602', 'Antennas and Wave Propagation', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC602' OR s.subject_name = 'Antennas and Wave Propagation')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC603', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC603' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC604', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC604' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 7
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC701', 'VLSI Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC701' OR s.subject_name = 'VLSI Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC702', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC702' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC703', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC703' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Branch: EC | Semester 8
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC801', 'Optical Fibre Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC801' OR s.subject_name = 'Optical Fibre Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC802', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC802' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'EC803', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'EC'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'EC803' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 1
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT102', 'Mathematics-I', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT102' OR s.subject_name = 'Mathematics-I')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT201', 'Engineering Physics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT201' OR s.subject_name = 'Engineering Physics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT203', 'Basic Mechanical Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT203' OR s.subject_name = 'Basic Mechanical Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT204', 'Basic Civil Engineering & Mechanics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT204' OR s.subject_name = 'Basic Civil Engineering & Mechanics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT205', 'Basic Computer Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT205' OR s.subject_name = 'Basic Computer Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT206', 'Language Lab & Seminars', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 1'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT206' OR s.subject_name = 'Language Lab & Seminars')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 2
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT101', 'Engineering Chemistry', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT101' OR s.subject_name = 'Engineering Chemistry')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT103', 'English for Communication', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT103' OR s.subject_name = 'English for Communication')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT104', 'Basic Electrical & Electronics Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT104' OR s.subject_name = 'Basic Electrical & Electronics Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT105', 'Engineering Graphics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT105' OR s.subject_name = 'Engineering Graphics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT202', 'Mathematics-II', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT202' OR s.subject_name = 'Mathematics-II')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT106', 'Manufacturing Practices', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 2'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT106' OR s.subject_name = 'Manufacturing Practices')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 3
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'BT301', 'Mathematics-III', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'BT301' OR s.subject_name = 'Mathematics-III')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME302', 'Thermodynamics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME302' OR s.subject_name = 'Thermodynamics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME303', 'Materials Technology', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME303' OR s.subject_name = 'Materials Technology')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME304', 'Strength of Material', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME304' OR s.subject_name = 'Strength of Material')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME305', 'Manufacturing Process', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 3'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME305' OR s.subject_name = 'Manufacturing Process')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 4
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ES401', 'Energy & Environmental Engineering', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ES401' OR s.subject_name = 'Energy & Environmental Engineering')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME402', 'Instrumentation & Control', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME402' OR s.subject_name = 'Instrumentation & Control')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME403', 'Theory of Machines', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME403' OR s.subject_name = 'Theory of Machines')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME404', 'Fluid Mechanics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME404' OR s.subject_name = 'Fluid Mechanics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME405', 'Manufacturing Technology', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 4'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME405' OR s.subject_name = 'Manufacturing Technology')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 5
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME501', 'I.C. Engines', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME501' OR s.subject_name = 'I.C. Engines')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME502', 'Mechanical Vibration', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME502' OR s.subject_name = 'Mechanical Vibration')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME503', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME503' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME504', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 5'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME504' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 6
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME601', 'Thermal Engineering and Gas Dynamics', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME601' OR s.subject_name = 'Thermal Engineering and Gas Dynamics')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME602', 'Machine Component Design', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME602' OR s.subject_name = 'Machine Component Design')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME603', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME603' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME604', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 6'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME604' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 7
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME701', 'Heat and Mass Transfer', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME701' OR s.subject_name = 'Heat and Mass Transfer')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME702', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME702' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME703', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 7'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME703' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Branch: ME | Semester 8
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME801', 'Refrigeration & Air Conditioning', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME801' OR s.subject_name = 'Refrigeration & Air Conditioning')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME802', 'Departmental Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME802' OR s.subject_name = 'Departmental Elective')
  );

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT 'ME803', 'Open Elective', sem.semester_id
FROM semesters sem
JOIN branches b ON b.branch_id = sem.branch_id
WHERE b.branch_name = 'ME'
  AND sem.semester_name = 'Semester 8'
  AND NOT EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.semester_id = sem.semester_id
        AND (s.subject_code = 'ME803' OR s.subject_name = 'Open Elective')
  );

-- ----------------------------------------------------------------------------
-- Seed Units 1 to 5 for all EC and ME subjects
-- ----------------------------------------------------------------------------
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
JOIN semesters sem ON s.semester_id = sem.semester_id
JOIN branches b ON sem.branch_id = b.branch_id
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE b.branch_name IN ('EC', 'ME')
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
    AND u.unit_number = n.unit_number
);

COMMIT;
