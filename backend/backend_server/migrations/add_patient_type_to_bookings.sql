-- Add patient_type column to test_bookings table
-- This allows tracking whether a booking is for a student, staff, or outpatient
-- and ensures correct pricing is applied

ALTER TABLE test_bookings 
ADD COLUMN IF NOT EXISTS patient_type VARCHAR(20) DEFAULT 'outpatient';

-- Update existing records based on is_external_patient flag
-- External patients default to 'outpatient'
UPDATE test_bookings 
SET patient_type = 'outpatient' 
WHERE is_external_patient = true;

-- For internal patients, infer patient_type from users table role
UPDATE test_bookings tb
SET patient_type = CASE
    WHEN u.role = 'STUDENT' THEN 'student'
    WHEN u.role IN ('TEACHER', 'STAFF', 'DOCTOR', 'DISPENSER', 'LABSTAFF', 'ADMIN') THEN 'staff'
    ELSE 'outpatient'
END
FROM users u
WHERE tb.patient_id = u.user_id 
AND tb.is_external_patient = false;
