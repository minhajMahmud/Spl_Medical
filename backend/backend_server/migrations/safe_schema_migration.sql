-- Safe Migration: Apply Normalized Schema Changes
-- Run this after backing up your database
-- psql -h localhost -p 8090 -U postgres -d dishari_dev -f safe_schema_migration.sql

-- Step 1: Create ENUM types if they don't exist
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('STUDENT','TEACHER','STAFF','DOCTOR','DISPENSER','LABSTAFF','ADMIN','OUTSIDE');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE test_booking_status AS ENUM ('PENDING','COMPLETED');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE test_result_status AS ENUM ('PENDING','COMPLETED');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Step 2: Rename old tables to backup
ALTER TABLE IF EXISTS test_results RENAME TO test_results_old;
ALTER TABLE IF EXISTS booking_tests RENAME TO booking_tests_old;
ALTER TABLE IF EXISTS test_bookings RENAME TO test_bookings_old;
ALTER TABLE IF EXISTS patient_profiles RENAME TO patient_profiles_old;
ALTER TABLE IF EXISTS staff_profiles RENAME TO staff_profiles_old;
ALTER TABLE IF EXISTS users RENAME TO users_old;
ALTER TABLE IF EXISTS lab_tests RENAME TO lab_tests_old;

-- Step 3: Create new normalized tables
-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150) UNIQUE,
    password_hash VARCHAR(255),
    phone VARCHAR(20) UNIQUE NOT NULL,
    role user_role,
    is_active BOOLEAN DEFAULT TRUE,
    profile_picture_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staff profiles
CREATE TABLE IF NOT EXISTS staff_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    specialization VARCHAR(100),
    qualification VARCHAR(100),
    joining_date DATE
);

-- Patient profiles
CREATE TABLE IF NOT EXISTS patient_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    blood_group VARCHAR(10),
    allergies TEXT
);

-- Lab tests
CREATE TABLE IF NOT EXISTS lab_tests (
    test_id BIGSERIAL PRIMARY KEY,
    test_name VARCHAR(100),
    description TEXT,
    student_fee NUMERIC(10,2) DEFAULT 0.00,
    staff_fee NUMERIC(10,2) DEFAULT 0.00,
    outside_fee NUMERIC(10,2) DEFAULT 0.00,
    available BOOLEAN DEFAULT TRUE
);

-- Test bookings
CREATE TABLE IF NOT EXISTS test_bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT REFERENCES users(user_id),
    booking_date DATE DEFAULT CURRENT_DATE,
    is_external_patient BOOLEAN DEFAULT FALSE,
    external_patient_name VARCHAR(100),
    external_patient_phone VARCHAR(20),
    external_patient_email VARCHAR(150),
    status test_booking_status DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Booking tests (junction table)
CREATE TABLE IF NOT EXISTS booking_tests (
    booking_test_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES test_bookings(booking_id) ON DELETE CASCADE,
    test_id BIGINT NOT NULL REFERENCES lab_tests(test_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (booking_id, test_id)
);

-- Test results
CREATE TABLE IF NOT EXISTS test_results (
    result_id BIGSERIAL PRIMARY KEY,
    booking_test_id BIGINT UNIQUE NOT NULL REFERENCES booking_tests(booking_test_id) ON DELETE CASCADE,
    staff_id BIGINT REFERENCES users(user_id),
    status test_result_status DEFAULT 'PENDING',
    result_date DATE,
    attachment_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 4: Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_test_bookings_patient_id ON test_bookings(patient_id);
CREATE INDEX IF NOT EXISTS idx_test_bookings_booking_date ON test_bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_booking_tests_booking_id ON booking_tests(booking_id);
CREATE INDEX IF NOT EXISTS idx_test_results_staff_id ON test_results(staff_id);
CREATE INDEX IF NOT EXISTS idx_test_results_status ON test_results(status);

-- Step 5: Migrate data if old tables exist (optional - only if you have data to preserve)
-- NOTE: Uncomment the sections below if you want to migrate data from old tables
-- WARNING: This requires careful mapping of old to new schema

/*
-- Example: Insert sample data into lab_tests if empty
INSERT INTO lab_tests (test_name, description, student_fee, staff_fee, outside_fee, available)
SELECT DISTINCT test_name, description, student_fee, staff_fee, outside_fee, available
FROM lab_tests_old
WHERE NOT EXISTS (SELECT 1 FROM lab_tests);
*/

-- Step 6: Verify migration
SELECT 'Users table' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 'Staff profiles', COUNT(*) FROM staff_profiles
UNION ALL
SELECT 'Patient profiles', COUNT(*) FROM patient_profiles
UNION ALL
SELECT 'Lab tests', COUNT(*) FROM lab_tests
UNION ALL
SELECT 'Test bookings', COUNT(*) FROM test_bookings
UNION ALL
SELECT 'Booking tests', COUNT(*) FROM booking_tests
UNION ALL
SELECT 'Test results', COUNT(*) FROM test_results;

-- Step 7: Display ENUM types
SELECT format('%I', t.typname) as type_name, 
       array_agg(e.enumlabel ORDER BY e.enumsortorder) as values
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname IN ('user_role', 'test_booking_status', 'test_result_status')
GROUP BY t.typname
ORDER BY t.typname;

-- ===================================================================
-- IMPORTANT: After this migration, you can clean up old tables with:
-- DROP TABLE IF EXISTS test_results_old CASCADE;
-- DROP TABLE IF EXISTS booking_tests_old CASCADE;
-- DROP TABLE IF EXISTS test_bookings_old CASCADE;
-- DROP TABLE IF EXISTS patient_profiles_old CASCADE;
-- DROP TABLE IF EXISTS staff_profiles_old CASCADE;
-- DROP TABLE IF EXISTS users_old CASCADE;
-- DROP TABLE IF EXISTS lab_tests_old CASCADE;
-- ===================================================================
