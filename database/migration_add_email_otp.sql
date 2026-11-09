-- ============================================================================
-- U-NOTE Database Migration: Add Email OTP Verification & is_verified flag
-- ============================================================================

-- 1. Add is_verified flag to users table (default 1 for existing accounts)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified TINYINT(1) NOT NULL DEFAULT 1;

-- 2. Create email_otps table for secure verification code storage
CREATE TABLE IF NOT EXISTS email_otps (
    otp_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    email VARCHAR(100) NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    expires_at DATETIME NOT NULL,
    verified_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_user_id (user_id),
    KEY idx_email (email),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
