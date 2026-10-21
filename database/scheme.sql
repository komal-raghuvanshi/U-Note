
-- ============================================
-- U-NOTE: RGPV Notes & Study Resources Platform
-- Database Schema
-- Contains table definitions only
-- No sample users, passwords, or test data
-- ============================================

CREATE DATABASE IF NOT EXISTS u_note;
USE u_note;

-- 1. Branches
CREATE TABLE IF NOT EXISTS branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL UNIQUE
);

-- 2. Users
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student'
);

-- 3. Semesters
CREATE TABLE IF NOT EXISTS semesters (
    semester_id INT AUTO_INCREMENT PRIMARY KEY,
    semester_name VARCHAR(50) NOT NULL,
    branch_id INT NOT NULL,
    FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id),
    UNIQUE (semester_name, branch_id)
);

-- 4. Subjects
CREATE TABLE IF NOT EXISTS subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_code VARCHAR(20) NOT NULL,
    subject_name VARCHAR(150) NOT NULL,
    semester_id INT NOT NULL,
    FOREIGN KEY (semester_id)
        REFERENCES semesters(semester_id),
    UNIQUE (subject_code, semester_id)
);

-- 5. Units
CREATE TABLE IF NOT EXISTS units (
    unit_id INT AUTO_INCREMENT PRIMARY KEY,
    unit_number INT NOT NULL,
    unit_name VARCHAR(150) NOT NULL,
    subject_id INT NOT NULL,
    FOREIGN KEY (subject_id)
        REFERENCES subjects(subject_id),
    UNIQUE (subject_id, unit_number)
);

-- 6. Notes
CREATE TABLE IF NOT EXISTS notes (
    note_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    subject_id INT NOT NULL,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id)
        REFERENCES subjects(subject_id),
    FOREIGN KEY (uploaded_by)
        REFERENCES users(user_id)
);

-- 7. Previous Year Question Papers
CREATE TABLE IF NOT EXISTS pyqs (
    pyq_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    year YEAR,
    subject_id INT NOT NULL,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id)
        REFERENCES subjects(subject_id),
    FOREIGN KEY (uploaded_by)
        REFERENCES users(user_id)
);

-- 8. Resources
CREATE TABLE IF NOT EXISTS resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    resource_url VARCHAR(500) NOT NULL,
    resource_type VARCHAR(50),
    subject_id INT,
    uploaded_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unit_id INT NULL,
    description TEXT NULL,
    FOREIGN KEY (subject_id)
        REFERENCES subjects(subject_id),
    FOREIGN KEY (uploaded_by)
        REFERENCES users(user_id),
    FOREIGN KEY (unit_id)
        REFERENCES units(unit_id)
);

-- 9. Ratings
CREATE TABLE IF NOT EXISTS ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    resource_id INT NOT NULL,
    rating INT NOT NULL,
    review TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)
        REFERENCES users(user_id),
    FOREIGN KEY (resource_id)
        REFERENCES resources(resource_id),
    UNIQUE (user_id, resource_id),
    CHECK (rating BETWEEN 1 AND 5)
);

-- 10. Requests
CREATE TABLE IF NOT EXISTS requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject_id INT NOT NULL,
    unit_id INT NULL,
    request_description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)
        REFERENCES users(user_id),
    FOREIGN KEY (subject_id)
        REFERENCES subjects(subject_id),
    FOREIGN KEY (unit_id)
        REFERENCES units(unit_id),
    CHECK (status IN ('Pending', 'Fulfilled', 'Rejected'))
);

-- End of U-NOTE database schema
