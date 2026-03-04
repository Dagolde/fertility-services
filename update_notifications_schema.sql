-- Update notifications table schema
USE fertility_services;

-- Add new columns one by one
ALTER TABLE notifications ADD COLUMN channel ENUM('PUSH', 'EMAIL', 'SMS') DEFAULT 'PUSH' AFTER notification_type;
ALTER TABLE notifications ADD COLUMN status ENUM('PENDING', 'SENT', 'FAILED', 'DELIVERED') DEFAULT 'PENDING' AFTER channel;
ALTER TABLE notifications ADD COLUMN retry_count INT DEFAULT 0 AFTER status;
ALTER TABLE notifications ADD COLUMN scheduled_at DATETIME NULL AFTER retry_count;
ALTER TABLE notifications ADD COLUMN sent_at DATETIME NULL AFTER scheduled_at;
ALTER TABLE notifications ADD COLUMN delivered_at DATETIME NULL AFTER sent_at;
ALTER TABLE notifications ADD COLUMN failed_reason TEXT NULL AFTER delivered_at;
ALTER TABLE notifications ADD COLUMN data JSON NULL AFTER failed_reason;
ALTER TABLE notifications ADD COLUMN read_at DATETIME NULL AFTER is_read;
ALTER TABLE notifications ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- Update existing rows to have channel and status
UPDATE notifications SET channel = 'PUSH' WHERE channel IS NULL;
UPDATE notifications SET status = 'SENT' WHERE status IS NULL;

-- Now make them NOT NULL
ALTER TABLE notifications MODIFY COLUMN channel ENUM('PUSH', 'EMAIL', 'SMS') NOT NULL;
ALTER TABLE notifications MODIFY COLUMN user_id INT NOT NULL;

-- Update notification_type to ENUM (handle existing data first)
UPDATE notifications SET notification_type = 'SYSTEM' WHERE notification_type NOT IN ('APPOINTMENT_CONFIRMATION', 'APPOINTMENT_REMINDER', 'APPOINTMENT_CANCELLED', 'APPOINTMENT_RESCHEDULED', 'PAYMENT_CONFIRMATION', 'PAYMENT_REFUND', 'MESSAGE_RECEIVED', 'REVIEW_RESPONSE', 'MARKETING', 'SYSTEM');

ALTER TABLE notifications MODIFY COLUMN notification_type ENUM('APPOINTMENT_CONFIRMATION', 'APPOINTMENT_REMINDER', 'APPOINTMENT_CANCELLED', 'APPOINTMENT_RESCHEDULED', 'PAYMENT_CONFIRMATION', 'PAYMENT_REFUND', 'MESSAGE_RECEIVED', 'REVIEW_RESPONSE', 'MARKETING', 'SYSTEM') NOT NULL;

-- Create indexes (ignore if they already exist)
CREATE INDEX IF NOT EXISTS ix_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS ix_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS ix_notifications_scheduled_at ON notifications(scheduled_at);

-- Create notification_preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  channel ENUM('PUSH', 'EMAIL', 'SMS') NOT NULL,
  notification_type ENUM('APPOINTMENT_CONFIRMATION', 'APPOINTMENT_REMINDER', 'APPOINTMENT_CANCELLED', 'APPOINTMENT_RESCHEDULED', 'PAYMENT_CONFIRMATION', 'PAYMENT_REFUND', 'MESSAGE_RECEIVED', 'REVIEW_RESPONSE', 'MARKETING', 'SYSTEM') NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE KEY uq_user_channel_type (user_id, channel, notification_type),
  INDEX ix_notification_preferences_user_id (user_id)
);
