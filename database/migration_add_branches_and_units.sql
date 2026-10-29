-- ========================================================
-- U-NOTE: Database Migration - Add Missing Branches, Semesters & Units
-- Safe, repeatable migration. Does NOT delete any data.
-- ========================================================

USE u_note;

-- Extend existing users without changing or removing existing records.
SET @add_user_branch = IF(
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'branch_id') = 0,
    'ALTER TABLE users ADD COLUMN branch_id INT NULL',
    'SELECT 1'
);
PREPARE add_user_branch_stmt FROM @add_user_branch;
EXECUTE add_user_branch_stmt;
DEALLOCATE PREPARE add_user_branch_stmt;

SET @add_user_semester = IF(
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'semester_id') = 0,
    'ALTER TABLE users ADD COLUMN semester_id INT NULL',
    'SELECT 1'
);
PREPARE add_user_semester_stmt FROM @add_user_semester;
EXECUTE add_user_semester_stmt;
DEALLOCATE PREPARE add_user_semester_stmt;

SET @add_user_branch_fk = IF(
    (SELECT COUNT(*) FROM information_schema.table_constraints
     WHERE constraint_schema = DATABASE() AND table_name = 'users'
       AND constraint_name = 'fk_users_branch') = 0,
    'ALTER TABLE users ADD CONSTRAINT fk_users_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)',
    'SELECT 1'
);
PREPARE add_user_branch_fk_stmt FROM @add_user_branch_fk;
EXECUTE add_user_branch_fk_stmt;
DEALLOCATE PREPARE add_user_branch_fk_stmt;

SET @add_user_semester_fk = IF(
    (SELECT COUNT(*) FROM information_schema.table_constraints
     WHERE constraint_schema = DATABASE() AND table_name = 'users'
       AND constraint_name = 'fk_users_semester') = 0,
    'ALTER TABLE users ADD CONSTRAINT fk_users_semester FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)',
    'SELECT 1'
);
PREPARE add_user_semester_fk_stmt FROM @add_user_semester_fk;
EXECUTE add_user_semester_fk_stmt;
DEALLOCATE PREPARE add_user_semester_fk_stmt;

CREATE TABLE IF NOT EXISTS saved_resources (
    user_id INT NOT NULL,
    resource_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, resource_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id) ON DELETE CASCADE
);

-- 1. Insert remaining branches if they don't already exist
INSERT INTO branches (branch_name)
SELECT 'IT' WHERE NOT EXISTS (SELECT 1 FROM branches WHERE branch_name = 'IT');

INSERT INTO branches (branch_name)
SELECT 'EC' WHERE NOT EXISTS (SELECT 1 FROM branches WHERE branch_name = 'EC');

INSERT INTO branches (branch_name)
SELECT 'ME' WHERE NOT EXISTS (SELECT 1 FROM branches WHERE branch_name = 'ME');

INSERT INTO branches (branch_name)
SELECT 'Civil' WHERE NOT EXISTS (SELECT 1 FROM branches WHERE branch_name = 'Civil');

-- 2. Ensure all semesters 1-8 exist for all branches
INSERT INTO semesters (semester_name, branch_id)
SELECT sem_name, b.branch_id
FROM branches b
CROSS JOIN (
    SELECT 'Semester 1' AS sem_name UNION ALL
    SELECT 'Semester 2' UNION ALL
    SELECT 'Semester 3' UNION ALL
    SELECT 'Semester 4' UNION ALL
    SELECT 'Semester 5' UNION ALL
    SELECT 'Semester 6' UNION ALL
    SELECT 'Semester 7' UNION ALL
    SELECT 'Semester 8'
) s
WHERE NOT EXISTS (
    SELECT 1 FROM semesters existing
    WHERE existing.branch_id = b.branch_id
      AND existing.semester_name = s.sem_name
);

-- 3. Ensure Units 1-5 exist for all existing subjects
-- Subject 1: Artificial Intelligence (AIML401)
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 3, 'Knowledge Representation & Reasoning', 1
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 1 AND unit_number = 3);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 4, 'Planning & Learning Techniques', 1
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 1 AND unit_number = 4);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 5, 'Expert Systems & NLP', 1
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 1 AND unit_number = 5);

-- Subject 2: Machine Learning (AIML402)
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 3, 'Supervised & Unsupervised Learning', 2
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 2 AND unit_number = 3);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 4, 'Neural Networks & Deep Learning', 2
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 2 AND unit_number = 4);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 5, 'Reinforcement Learning & Applications', 2
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 2 AND unit_number = 5);

-- Subject 3: Software Engineering (AIML403)
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 2, 'Software Requirement Engineering', 3
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 3 AND unit_number = 2);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 3, 'Software Design & Architecture', 3
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 3 AND unit_number = 3);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 4, 'Software Testing & Quality Assurance', 3
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 3 AND unit_number = 4);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 5, 'Software Maintenance & Project Management', 3
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 3 AND unit_number = 5);

-- Subject 4: Data Structures (CSE301)
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 2, 'Stacks & Queues', 4
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 4 AND unit_number = 2);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 3, 'Trees & Binary Search Trees', 4
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 4 AND unit_number = 3);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 4, 'Graphs & Graph Algorithms', 4
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 4 AND unit_number = 4);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 5, 'Searching & Sorting Techniques', 4
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 4 AND unit_number = 5);

-- Subject 5: Database Management System (CSE302)
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 1, 'Introduction & ER Modeling', 5
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 5 AND unit_number = 1);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 2, 'Relational Model & Algebra', 5
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 5 AND unit_number = 2);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 3, 'SQL & Normalization', 5
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 5 AND unit_number = 3);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 4, 'Transaction Processing & Concurrency', 5
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 5 AND unit_number = 4);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 5, 'Recovery System & Query Optimization', 5
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 5 AND unit_number = 5);

-- Subject 6: Computer Networks (CSE401)
INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 1, 'Introduction & Physical Layer', 6
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 6 AND unit_number = 1);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 2, 'Data Link Layer & MAC Sublayer', 6
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 6 AND unit_number = 2);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 3, 'Network Layer & Routing Algorithms', 6
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 6 AND unit_number = 3);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 4, 'Transport Layer & Congestion Control', 6
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 6 AND unit_number = 4);

INSERT INTO units (unit_number, unit_name, subject_id)
SELECT 5, 'Application Layer & Network Security', 6
WHERE NOT EXISTS (SELECT 1 FROM units WHERE subject_id = 6 AND unit_number = 5);
