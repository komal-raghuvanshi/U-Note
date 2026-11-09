INSERT INTO branches (branch_name)
SELECT 'Electronics and Communication Engineering'
WHERE NOT EXISTS (
    SELECT 1 FROM branches
    WHERE branch_name = 'Electronics and Communication Engineering'
);

INSERT INTO branches (branch_name)
SELECT 'Mechanical Engineering'
WHERE NOT EXISTS (
    SELECT 1 FROM branches
    WHERE branch_name = 'Mechanical Engineering'
);
INSERT INTO semesters (semester_name, branch_id)
SELECT sem.semester_name, b.branch_id
FROM branches b
CROSS JOIN (
    SELECT 'Semester 1' AS semester_name
    UNION ALL SELECT 'Semester 2'
    UNION ALL SELECT 'Semester 3'
    UNION ALL SELECT 'Semester 4'
    UNION ALL SELECT 'Semester 5'
    UNION ALL SELECT 'Semester 6'
    UNION ALL SELECT 'Semester 7'
    UNION ALL SELECT 'Semester 8'
) AS sem
WHERE b.branch_name IN (
    'Electronics and Communication Engineering',
    'Mechanical Engineering'
)
AND NOT EXISTS (
    SELECT 1
    FROM semesters existing
    WHERE existing.branch_id = b.branch_id
      AND existing.semester_name = sem.semester_name
);

INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT new_data.subject_code, new_data.subject_name, new_data.semester_id
FROM (
    SELECT 'BT301' AS subject_code, 'Mathematics-III' AS subject_name, 14 AS semester_id
    UNION ALL SELECT 'EC302', 'Electronic Measurement & Instrumentation', 14
    UNION ALL SELECT 'EC303', 'Digital System Design', 14
    UNION ALL SELECT 'EC304', 'Electronic Devices', 14
    UNION ALL SELECT 'EC305', 'Network Analysis', 14

    UNION ALL SELECT 'ES401', 'Energy & Environmental Engineering', 16
    UNION ALL SELECT 'EC402', 'Signals & Systems', 16
    UNION ALL SELECT 'EC403', 'Analog Communication', 16
    UNION ALL SELECT 'EC404', 'Control System', 16
    UNION ALL SELECT 'EC405', 'Analog Circuits', 16

    UNION ALL SELECT 'EC501', 'Microprocessor & its Application', 18
    UNION ALL SELECT 'EC502', 'Digital Communication', 18
    UNION ALL SELECT 'EC503', 'Departmental Elective', 18
    UNION ALL SELECT 'EC504', 'Open Elective', 18

    UNION ALL SELECT 'EC601', 'Digital Signal Processing', 20
    UNION ALL SELECT 'EC602', 'Antennas and Wave Propagation', 20
    UNION ALL SELECT 'EC603', 'Departmental Elective', 20
    UNION ALL SELECT 'EC604', 'Open Elective', 20

    UNION ALL SELECT 'EC701', 'VLSI Design', 22
    UNION ALL SELECT 'EC702', 'Departmental Elective', 22
    UNION ALL SELECT 'EC703', 'Open Elective', 22

    UNION ALL SELECT 'EC801', 'Optical Fibre Communication', 24
    UNION ALL SELECT 'EC802', 'Departmental Elective', 24
    UNION ALL SELECT 'EC803', 'Open Elective', 24

    UNION ALL SELECT 'BT301', 'Mathematics-III', 13
    UNION ALL SELECT 'ME302', 'Thermodynamics', 13
    UNION ALL SELECT 'ME303', 'Materials Technology', 13
    UNION ALL SELECT 'ME304', 'Strength of Material', 13
    UNION ALL SELECT 'ME305', 'Manufacturing Process', 13

    UNION ALL SELECT 'ES401', 'Energy & Environmental Engineering', 15
    UNION ALL SELECT 'ME402', 'Instrumentation & Control', 15
    UNION ALL SELECT 'ME403', 'Theory of Machines', 15
    UNION ALL SELECT 'ME404', 'Fluid Mechanics', 15
    UNION ALL SELECT 'ME405', 'Manufacturing Technology', 15

    UNION ALL SELECT 'ME501', 'I.C. Engines', 17
    UNION ALL SELECT 'ME502', 'Mechanical Vibration', 17
    UNION ALL SELECT 'ME503', 'Departmental Elective', 17
    UNION ALL SELECT 'ME504', 'Open Elective', 17

    UNION ALL SELECT 'ME601', 'Thermal Engineering and Gas Dynamics', 19
    UNION ALL SELECT 'ME602', 'Machine Component Design', 19
    UNION ALL SELECT 'ME603', 'Departmental Elective', 19
    UNION ALL SELECT 'ME604', 'Open Elective', 19

    UNION ALL SELECT 'ME701', 'Heat and Mass Transfer', 21
    UNION ALL SELECT 'ME702', 'Departmental Elective', 21
    UNION ALL SELECT 'ME703', 'Open Elective', 21

    UNION ALL SELECT 'ME801', 'Refrigeration & Air Conditioning', 23
    UNION ALL SELECT 'ME802', 'Departmental Elective', 23
    UNION ALL SELECT 'ME803', 'Open Elective', 23
) AS new_data
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects existing
    WHERE existing.subject_code = new_data.subject_code
      AND existing.semester_id = new_data.semester_id
);
SELECT
    b.branch_name,
    sem.semester_name,
    sub.subject_code,
    sub.subject_name
FROM subjects sub
JOIN semesters sem ON sub.semester_id = sem.semester_id
JOIN branches b ON sem.branch_id = b.branch_id
WHERE b.branch_name IN (
    'Electronics and Communication Engineering',
    'Mechanical Engineering'
)
ORDER BY b.branch_name, sem.semester_id, sub.subject_id;


INSERT INTO subjects (subject_code, subject_name, semester_id)
SELECT new_data.subject_code, new_data.subject_name, new_data.semester_id
FROM (
    SELECT 'BT102' AS subject_code, 'Mathematics-I' AS subject_name, 10 AS semester_id
    UNION ALL SELECT 'BT201', 'Engineering Physics', 10
    UNION ALL SELECT 'BT203', 'Basic Mechanical Engineering', 10
    UNION ALL SELECT 'BT204', 'Basic Civil Engineering & Mechanics', 10
    UNION ALL SELECT 'BT205', 'Basic Computer Engineering', 10
    UNION ALL SELECT 'BT206', 'Language Lab & Seminars', 10

    UNION ALL SELECT 'BT101', 'Engineering Chemistry', 12
    UNION ALL SELECT 'BT103', 'English for Communication', 12
    UNION ALL SELECT 'BT104', 'Basic Electrical & Electronics Engineering', 12
    UNION ALL SELECT 'BT105', 'Engineering Graphics', 12
    UNION ALL SELECT 'BT202', 'Mathematics-II', 12
    UNION ALL SELECT 'BT106', 'Manufacturing Practices', 12

    UNION ALL SELECT 'BT102', 'Mathematics-I', 9
    UNION ALL SELECT 'BT201', 'Engineering Physics', 9
    UNION ALL SELECT 'BT203', 'Basic Mechanical Engineering', 9
    UNION ALL SELECT 'BT204', 'Basic Civil Engineering & Mechanics', 9
    UNION ALL SELECT 'BT205', 'Basic Computer Engineering', 9
    UNION ALL SELECT 'BT206', 'Language Lab & Seminars', 9

    UNION ALL SELECT 'BT101', 'Engineering Chemistry', 11
    UNION ALL SELECT 'BT103', 'English for Communication', 11
    UNION ALL SELECT 'BT104', 'Basic Electrical & Electronics Engineering', 11
    UNION ALL SELECT 'BT105', 'Engineering Graphics', 11
    UNION ALL SELECT 'BT202', 'Mathematics-II', 11
    UNION ALL SELECT 'BT106', 'Manufacturing Practices', 11
) AS new_data
WHERE NOT EXISTS (
    SELECT 1
    FROM subjects existing
    WHERE existing.subject_code = new_data.subject_code
      AND existing.semester_id = new_data.semester_id
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC305'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC304'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
SELECT subject_id, subject_code, subject_name
FROM subjects
WHERE subject_code = 'EC303';
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC303'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'BT301'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
    UNION ALL SELECT 6
) n
WHERE s.subject_code = 'ES401'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC402'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC403'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC404'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC405'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC501'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC502'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
SELECT
    s.subject_code,
    s.subject_name,
    COUNT(u.unit_id) AS total_units
FROM subjects s
LEFT JOIN units u ON s.subject_id = u.subject_id
WHERE s.subject_code = 'EC504'
GROUP BY s.subject_id, s.subject_code, s.subject_name;
SELECT
    s.subject_code,
    s.subject_name,
    COUNT(u.unit_id) AS total_units
FROM subjects s
LEFT JOIN units u ON s.subject_id = u.subject_id
WHERE s.subject_code = 'EC601'
GROUP BY s.subject_id, s.subject_code, s.subject_name;
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC601'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number,
       CONCAT('Unit ', n.unit_number),
       s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC602'
AND NOT EXISTS (
    SELECT 1
    FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
SELECT
    s.subject_code,
    s.subject_name,
    COUNT(u.unit_id) AS total_units
FROM subjects s
LEFT JOIN units u ON s.subject_id = u.subject_id
WHERE s.subject_code = 'EC604'
GROUP BY s.subject_id, s.subject_code, s.subject_name;
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC701'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'EC801'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME302'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME303'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME304'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME305'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME402'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME403'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME404'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME405'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME501'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME502'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME601'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME602'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME801'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT n.unit_number, CONCAT('Unit ', n.unit_number), s.subject_id
FROM subjects s
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) n
WHERE s.subject_code = 'ME701'
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
      AND u.unit_number = n.unit_number
);
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
WHERE b.branch_name = 'Electronics and Communication Engineering'
AND sem.semester_name = 'Semester 1'
AND s.subject_code IN (
    'BT102', 'BT201', 'BT203',
    'BT204', 'BT205', 'BT206'
)
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
    AND u.unit_number = n.unit_number
);
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
WHERE b.branch_name = 'Electronics and Communication Engineering'
AND sem.semester_name = 'Semester 2'
AND s.subject_code IN (
    'BT101', 'BT103', 'BT104',
    'BT105', 'BT202', 'BT106'
)
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
    AND u.unit_number = n.unit_number
);
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
WHERE b.branch_name = 'Mechanical Engineering'
AND sem.semester_name = 'Semester 1'
AND s.subject_code IN (
    'BT102', 'BT201', 'BT203',
    'BT204', 'BT205', 'BT206'
)
AND NOT EXISTS (
    SELECT 1 FROM units u
    WHERE u.subject_id = s.subject_id
    AND u.unit_number = n.unit_number
);

