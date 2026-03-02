-- Initialize the fertility services database
CREATE DATABASE IF NOT EXISTS fertility_services;
USE fertility_services;

-- Create admin user
INSERT INTO users (email, password_hash, first_name, last_name, user_type, is_active, is_verified, profile_completed, created_at, updated_at)
VALUES (
    'admin@fertilityservices.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', -- password: admin123
    'System',
    'Administrator',
    'admin',
    1,
    1,
    1,
    NOW(),
    NOW()
);

-- Create sample services
INSERT INTO services (name, service_type, description, base_price, is_active, created_at, updated_at)
VALUES 
    ('Sperm Donation Consultation', 'sperm_donation', 'Initial consultation for sperm donation process', 150.00, 1, NOW(), NOW()),
    ('Sperm Donation Procedure', 'sperm_donation', 'Complete sperm donation procedure with screening', 500.00, 1, NOW(), NOW()),
    ('Egg Donation Consultation', 'egg_donation', 'Initial consultation for egg donation process', 200.00, 1, NOW(), NOW()),
    ('Egg Donation Procedure', 'egg_donation', 'Complete egg donation procedure with screening', 2500.00, 1, NOW(), NOW()),
    ('Surrogacy Consultation', 'surrogacy', 'Initial consultation for surrogacy process', 300.00, 1, NOW(), NOW()),
    ('Surrogacy Matching Service', 'surrogacy', 'Professional surrogacy matching and coordination', 5000.00, 1, NOW(), NOW());

-- Create sample hospital user
INSERT INTO users (email, password_hash, first_name, last_name, user_type, is_active, is_verified, profile_completed, created_at, updated_at)
VALUES (
    'hospital@example.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', -- password: hospital123
    'City',
    'Fertility Center',
    'hospital',
    1,
    1,
    1,
    NOW(),
    NOW()
);

-- Create sample hospital
INSERT INTO hospitals (user_id, name, license_number, address, city, state, country, zip_code, phone, email, website, description, services_offered, is_verified, rating, created_at, updated_at)
VALUES (
    2, -- hospital user id
    'City Fertility Center',
    'LIC-2024-001',
    '123 Medical Plaza, Suite 100',
    'New York',
    'NY',
    'USA',
    '10001',
    '+1-555-0123',
    'info@cityfertility.com',
    'https://cityfertility.com',
    'Leading fertility center providing comprehensive reproductive services',
    '["sperm_donation", "egg_donation", "surrogacy"]',
    1,
    4.8,
    NOW(),
    NOW()
);

-- Create sample patient users
INSERT INTO users (email, password_hash, first_name, last_name, phone, user_type, is_active, is_verified, profile_completed, created_at, updated_at)
VALUES 
    ('patient1@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', 'John', 'Doe', '+1-555-0001', 'patient', 1, 1, 1, NOW(), NOW()),
    ('patient2@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', 'Jane', 'Smith', '+1-555-0002', 'patient', 1, 1, 1, NOW(), NOW()),
    ('donor1@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', 'Mike', 'Johnson', '+1-555-0003', 'sperm_donor', 1, 1, 1, NOW(), NOW()),
    ('donor2@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', 'Sarah', 'Wilson', '+1-555-0004', 'egg_donor', 1, 1, 1, NOW(), NOW()),
    ('surrogate1@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', 'Emily', 'Brown', '+1-555-0005', 'surrogate', 1, 1, 1, NOW(), NOW());

-- Create user profiles
INSERT INTO user_profiles (user_id, bio, address, city, state, country, zip_code, created_at, updated_at)
VALUES 
    (3, 'Looking for fertility services to start a family', '456 Oak Street', 'New York', 'NY', 'USA', '10002', NOW(), NOW()),
    (4, 'Seeking egg donation services', '789 Pine Avenue', 'Brooklyn', 'NY', 'USA', '11201', NOW(), NOW()),
    (5, 'Experienced sperm donor willing to help couples', '321 Elm Street', 'Queens', 'NY', 'USA', '11101', NOW(), NOW()),
    (6, 'Healthy egg donor with medical clearance', '654 Maple Drive', 'Manhattan', 'NY', 'USA', '10003', NOW(), NOW()),
    (7, 'Experienced surrogate mother', '987 Cedar Lane', 'Bronx', 'NY', 'USA', '10451', NOW(), NOW());

-- Create sample appointments
INSERT INTO appointments (user_id, hospital_id, service_id, appointment_date, status, notes, price, created_at, updated_at)
VALUES 
    (3, 1, 1, '2024-02-15 10:00:00', 'confirmed', 'Initial consultation for sperm donation', 150.00, NOW(), NOW()),
    (4, 1, 3, '2024-02-16 14:00:00', 'pending', 'Consultation for egg donation process', 200.00, NOW(), NOW()),
    (3, 1, 5, '2024-02-20 09:00:00', 'pending', 'Surrogacy consultation appointment', 300.00, NOW(), NOW());

-- Create sample payments
INSERT INTO payments (user_id, appointment_id, amount, payment_method, transaction_id, status, payment_date, created_at, updated_at)
VALUES 
    (3, 1, 150.00, 'credit_card', 'TXN_001_20240201', 'completed', NOW(), NOW(), NOW());

-- Create sample messages
INSERT INTO messages (sender_id, receiver_id, content, is_read, created_at)
VALUES 
    (3, 2, 'Hello, I would like to schedule an appointment for fertility consultation.', 1, NOW()),
    (2, 3, 'Thank you for your interest. We have availability next week. Please let us know your preferred time.', 0, NOW()),
    (4, 5, 'Hi, I am interested in learning more about the sperm donation process.', 1, NOW()),
    (5, 4, 'Hello! I would be happy to discuss the process with you. When would be a good time to talk?', 0, NOW());

-- Create sample notifications
INSERT INTO notifications (user_id, title, message, notification_type, is_read, created_at)
VALUES 
    (3, 'Appointment Confirmed', 'Your appointment for February 15th has been confirmed.', 'appointment_confirmed', 0, NOW()),
    (4, 'New Message', 'You have received a new message from a donor.', 'new_message', 0, NOW()),
    (2, 'New Appointment Request', 'You have a new appointment request from John Doe.', 'appointment_request', 0, NOW());
