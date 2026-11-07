-- ============================================================================
-- U-NOTE Database Migration: Admin Panel, Resource Moderation,
-- Resource Reports, In-App & Push Notifications
-- ============================================================================

START TRANSACTION;

-- 1. Add is_blocked to users table (default 0)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_blocked TINYINT(1) NOT NULL DEFAULT 0;

-- 2. Add moderation, verification, and download tracking to resources table
ALTER TABLE resources ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NOT NULL DEFAULT 'approved';
ALTER TABLE resources ADD COLUMN IF NOT EXISTS is_verified TINYINT(1) NOT NULL DEFAULT 0;
ALTER TABLE resources ADD COLUMN IF NOT EXISTS download_count INT NOT NULL DEFAULT 0;

-- 3. Create resource_reports table
CREATE TABLE IF NOT EXISTS resource_reports (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_id INT NOT NULL,
    user_id INT NOT NULL,
    reason VARCHAR(100) NOT NULL,
    details TEXT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    admin_notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    resolved_by INT NULL,
    KEY idx_resource_id (resource_id),
    KEY idx_user_id (user_id),
    KEY idx_status (status),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 4. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    related_resource_id INT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_user_id (user_id),
    KEY idx_is_read (is_read),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 5. Create push_subscriptions table
CREATE TABLE IF NOT EXISTS push_subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    endpoint TEXT NOT NULL,
    p256dh VARCHAR(255) NOT NULL,
    auth VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

COMMIT;
