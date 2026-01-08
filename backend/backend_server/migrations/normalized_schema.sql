-- Migration: Implement Normalized Database Schema with ENUM Types and Proper Relationships
-- This migration creates the normalized schema with user roles and test booking management

-- Create ENUM types
CREATE TYPE user_role AS ENUM (
    'STUDENT','TEACHER','STAFF','DOCTOR','DISPENSER','LABSTAFF','ADMIN','OUTSIDE'
);

CREATE TYPE test_booking_status AS ENUM (
    'PENDING','COMPLETED'
);

CREATE TYPE test_result_status AS ENUM (
    'PENDING','COMPLETED'
);

-- Drop existing tables if they exist (for fresh migration)
DROP TABLE IF EXISTS test_results CASCADE;
DROP TABLE IF EXISTS booking_tests CASCADE;
DROP TABLE IF EXISTS test_bookings CASCADE;
DROP TABLE IF EXISTS patient_profiles CASCADE;
DROP TABLE IF EXISTS staff_profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS lab_tests CASCADE;

-- Create unified users table
CREATE TABLE users (
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

-- Create staff profiles table
CREATE TABLE staff_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    specialization VARCHAR(100),
    qualification VARCHAR(100),
    joining_date DATE
);

-- Create patient profiles table
CREATE TABLE patient_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    blood_group VARCHAR(10),
    allergies TEXT
);

-- Create lab tests table
CREATE TABLE lab_tests (
    test_id BIGSERIAL PRIMARY KEY,
    test_name VARCHAR(100),
    description TEXT,
    student_fee NUMERIC(10,2) DEFAULT 0.00,
    staff_fee NUMERIC(10,2) DEFAULT 0.00,
    outside_fee NUMERIC(10,2) DEFAULT 0.00,
    available BOOLEAN DEFAULT TRUE
);

-- Create test bookings table
CREATE TABLE test_bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT REFERENCES users(user_id),
    booking_date DATE DEFAULT CURRENT_DATE,
    is_external_patient BOOLEAN DEFAULT FALSE,
    status test_booking_status DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create booking tests junction table
CREATE TABLE booking_tests (
    booking_test_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES test_bookings(booking_id) ON DELETE CASCADE,
    test_id BIGINT NOT NULL REFERENCES lab_tests(test_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (booking_id, test_id)
);

-- Create test results table
CREATE TABLE test_results (
    result_id BIGSERIAL PRIMARY KEY,
    booking_test_id BIGINT UNIQUE NOT NULL REFERENCES booking_tests(booking_test_id) ON DELETE CASCADE,
    staff_id BIGINT REFERENCES users(user_id),
    status test_result_status DEFAULT 'PENDING',
    result_date DATE,
    attachment_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_test_bookings_patient_id ON test_bookings(patient_id);
CREATE INDEX idx_test_bookings_booking_date ON test_bookings(booking_date);
CREATE INDEX idx_booking_tests_booking_id ON booking_tests(booking_id);
CREATE INDEX idx_test_results_staff_id ON test_results(staff_id);
CREATE INDEX idx_test_results_status ON test_results(status);
