-- QUICK FIX: Minimal SQL patch to fix existing schema
-- This converts the current VARCHAR(20) booking_id to BIGSERIAL
-- and creates the junction table needed for multiple tests per booking

-- Step 1: Create ENUM types if they don't exist
DO $$ BEGIN
    CREATE TYPE test_booking_status AS ENUM ('PENDING','COMPLETED');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE test_result_status AS ENUM ('PENDING','COMPLETED');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Step 2: Backup existing data
CREATE TABLE test_bookings_backup AS SELECT * FROM test_bookings;
CREATE TABLE test_results_backup AS SELECT * FROM test_results;

-- Step 3: Drop dependent constraints
ALTER TABLE test_results DROP CONSTRAINT IF EXISTS test_results_booking_id_key;
ALTER TABLE test_results DROP CONSTRAINT IF EXISTS test_results_booking_id_fkey;
DELETE FROM test_results;

-- Step 4: Convert test_bookings table structure
ALTER TABLE test_bookings 
  DROP CONSTRAINT test_bookings_pkey;

ALTER TABLE test_bookings 
  ADD COLUMN booking_id_new BIGSERIAL PRIMARY KEY;

-- Step 5: Copy data and create proper structure
UPDATE test_bookings SET booking_id_new = booking_id::BIGINT;

ALTER TABLE test_bookings 
  DROP COLUMN booking_id;

ALTER TABLE test_bookings 
  RENAME COLUMN booking_id_new TO booking_id;

-- Step 6: Add/update status column with ENUM type
ALTER TABLE test_bookings 
  DROP COLUMN IF EXISTS status;

ALTER TABLE test_bookings 
  ADD COLUMN status test_booking_status DEFAULT 'PENDING';

-- Step 7: Add timestamps if missing
ALTER TABLE test_bookings 
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Step 8: Create booking_tests junction table (NEW)
CREATE TABLE IF NOT EXISTS booking_tests (
    booking_test_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES test_bookings(booking_id) ON DELETE CASCADE,
    test_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (booking_id, test_id)
);

-- Step 9: Update test_results table
ALTER TABLE test_results 
  DROP COLUMN IF EXISTS booking_id;

ALTER TABLE test_results 
  ADD COLUMN booking_test_id BIGINT UNIQUE REFERENCES booking_tests(booking_test_id) ON DELETE CASCADE;

ALTER TABLE test_results 
  ADD COLUMN IF NOT EXISTS status test_result_status DEFAULT 'PENDING';

ALTER TABLE test_results 
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Step 10: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_test_bookings_patient_id ON test_bookings(patient_id);
CREATE INDEX IF NOT EXISTS idx_test_bookings_booking_date ON test_bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_booking_tests_booking_id ON booking_tests(booking_id);
CREATE INDEX IF NOT EXISTS idx_test_results_staff_id ON test_results(staff_id);

-- Step 11: Verify migration
SELECT 'MIGRATION COMPLETE' as status;
SELECT '✓ test_bookings updated' as result, COUNT(*) as count FROM test_bookings
UNION ALL
SELECT '✓ booking_tests created', COUNT(*) FROM booking_tests
UNION ALL
SELECT '✓ test_results updated', COUNT(*) FROM test_results;

-- Step 12: Show column info
SELECT 'test_bookings columns' as table_name;
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'test_bookings' 
ORDER BY ordinal_position;
