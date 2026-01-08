-- FIX: Convert test_bookings.booking_id from VARCHAR(20) to BIGSERIAL
-- This fixes the "null value in column booking_id" error

-- Step 1: Drop dependent tables in correct order
DROP TABLE IF EXISTS test_results CASCADE;
DROP TABLE IF EXISTS booking_tests CASCADE;
DROP TABLE IF EXISTS test_bookings CASCADE;

-- Step 2: Fix lab_tests - test_id should be BIGSERIAL or BIGINT
ALTER TABLE lab_tests 
  DROP CONSTRAINT lab_tests_pkey;

ALTER TABLE lab_tests 
  ADD COLUMN test_id_new BIGSERIAL PRIMARY KEY;

-- Copy existing IDs
UPDATE lab_tests SET test_id_new = test_id;

-- Drop old column and rename
ALTER TABLE lab_tests 
  DROP COLUMN test_id;

ALTER TABLE lab_tests 
  RENAME COLUMN test_id_new TO test_id;

-- Step 3: Fix staff_profiles - add ON DELETE CASCADE
ALTER TABLE staff_profiles 
  DROP CONSTRAINT staff_profiles_user_id_fkey;

ALTER TABLE staff_profiles 
  ADD CONSTRAINT staff_profiles_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- Step 4: Recreate test_bookings with BIGSERIAL booking_id
CREATE TABLE test_bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT REFERENCES users(user_id),
    booking_date DATE DEFAULT CURRENT_DATE,
    is_external_patient BOOLEAN DEFAULT FALSE,
    status test_booking_status DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 5: Recreate booking_tests junction table
CREATE TABLE booking_tests (
    booking_test_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES test_bookings(booking_id) ON DELETE CASCADE,
    test_id BIGINT NOT NULL REFERENCES lab_tests(test_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (booking_id, test_id)
);

-- Step 6: Recreate test_results with booking_test_id reference
CREATE TABLE test_results (
    result_id BIGSERIAL PRIMARY KEY,
    booking_test_id BIGINT UNIQUE NOT NULL
        REFERENCES booking_tests(booking_test_id) ON DELETE CASCADE,
    staff_id BIGINT REFERENCES users(user_id),
    status test_result_status DEFAULT 'PENDING',
    result_date DATE,
    attachment_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 7: Create indexes for performance
CREATE INDEX idx_test_bookings_patient_id ON test_bookings(patient_id);
CREATE INDEX idx_test_bookings_booking_date ON test_bookings(booking_date);
CREATE INDEX idx_test_bookings_status ON test_bookings(status);
CREATE INDEX idx_booking_tests_booking_id ON booking_tests(booking_id);
CREATE INDEX idx_test_results_staff_id ON test_results(staff_id);
CREATE INDEX idx_test_results_status ON test_results(status);

-- Step 8: Verify the fix
SELECT 'SCHEMA FIX COMPLETE' as status;

SELECT 
  'test_bookings' as table_name, 
  COUNT(*) as row_count 
FROM test_bookings
UNION ALL
SELECT 'booking_tests', COUNT(*) FROM booking_tests
UNION ALL
SELECT 'test_results', COUNT(*) FROM test_results
UNION ALL
SELECT 'lab_tests', COUNT(*) FROM lab_tests;

-- Show test_bookings structure
SELECT 
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'test_bookings' 
ORDER BY ordinal_position;
