# Step-by-Step Fix for "booking not found" Error

## IMPORTANT: You Do NOT Enter booking_id Manually!

❌ **WRONG**: Trying to INSERT booking_id manually (VARCHAR or BIGINT)  
✅ **CORRECT**: Let the database AUTO-GENERATE booking_id (BIGSERIAL)

---

## Step 1: Run the SQL Fix (Complete Block)

**Open pgAdmin4** → Select your database → **Tools** → **Query Tool**

Copy and paste **ALL OF THIS** (the complete block):

```sql
-- IMPORTANT: This recreates the tables with auto-generating booking_id
-- DO NOT try to insert booking_id values manually!

-- Step 1: Drop old tables
DROP TABLE IF EXISTS test_results CASCADE;
DROP TABLE IF EXISTS booking_tests CASCADE;
DROP TABLE IF EXISTS test_bookings CASCADE;

-- Step 2: Create test_bookings with AUTO-INCREMENTING booking_id
CREATE TABLE test_bookings (
    booking_id BIGSERIAL PRIMARY KEY,              -- ← AUTO-GENERATED, never enter manually!
    patient_id BIGINT REFERENCES users(user_id),
    booking_date DATE DEFAULT CURRENT_DATE,
    is_external_patient BOOLEAN DEFAULT FALSE,
    status test_booking_status DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Create booking_tests junction table
CREATE TABLE booking_tests (
    booking_test_id BIGSERIAL PRIMARY KEY,         -- ← AUTO-GENERATED
    booking_id BIGINT NOT NULL REFERENCES test_bookings(booking_id) ON DELETE CASCADE,
    test_id BIGINT NOT NULL REFERENCES lab_tests(test_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (booking_id, test_id)
);

-- Step 4: Create test_results table
CREATE TABLE test_results (
    result_id BIGSERIAL PRIMARY KEY,               -- ← AUTO-GENERATED
    booking_test_id BIGINT UNIQUE NOT NULL
        REFERENCES booking_tests(booking_test_id) ON DELETE CASCADE,
    staff_id BIGINT REFERENCES users(user_id),
    status test_result_status DEFAULT 'PENDING',
    result_date DATE,
    attachment_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 5: Create indexes for performance
CREATE INDEX idx_test_bookings_patient_id ON test_bookings(patient_id);
CREATE INDEX idx_test_bookings_booking_date ON test_bookings(booking_date);
CREATE INDEX idx_test_bookings_status ON test_bookings(status);
CREATE INDEX idx_booking_tests_booking_id ON booking_tests(booking_id);
CREATE INDEX idx_test_results_staff_id ON test_results(staff_id);
CREATE INDEX idx_test_results_status ON test_results(status);

-- Done!
SELECT 'SCHEMA FIX COMPLETE ✅' as status;
```

**Click Execute (F5)**

---

## Step 2: Verify Schema is Correct

Run this in Query Tool:

```sql
-- Check if booking_id is now BIGINT (auto-increment)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'test_bookings' AND column_name = 'booking_id';
```

**Expected Output:**

```
column_name | data_type
------------+-----------
booking_id  | bigint      ← Should be "bigint" NOT "character varying"
```

✅ If it says "bigint" → Schema is fixed!  
❌ If it says "character varying" → SQL didn't run, try again

---

## Step 3: Restart Backend

Close the running backend (Ctrl+C) and restart:

```bash
cd backend/backend_server
dart bin/main.dart
```

Wait for: `Server running on http://0.0.0.0:8080/`

---

## Step 4: Test with Your App

1. **Create a NEW booking** in your app (with multiple tests if you want)
2. Backend will **automatically generate** booking_id (like 1, 2, 3, etc.)
3. App will show "BK000001", "BK000002", etc.
4. **Upload test result** - should work now! ✅

---

## What Changed

### Before (OLD - BROKEN):

```sql
CREATE TABLE test_bookings (
    booking_id VARCHAR(20) PRIMARY KEY,  -- ❌ You had to enter this manually
    ...
);
```

### After (NEW - AUTO-GENERATE):

```sql
CREATE TABLE test_bookings (
    booking_id BIGSERIAL PRIMARY KEY,    -- ✅ Database generates automatically
    ...
);
```

---

## How Booking Creation Works Now

**Backend Code:**

```dart
// When creating a booking, backend does:
INSERT INTO test_bookings (patient_id, booking_date, status)
VALUES (123, '2026-01-07', 'PENDING')
RETURNING booking_id;  // ← Database returns 1, 2, 3, 4... (auto-generated)
```

**What You See:**

- Backend gets: `booking_id = 1`
- App shows: `"BK000001"`
- Upload result for: `"BK000001"` → Works! ✅

---

## If You Still Get Errors

### Error: "type test_booking_status does not exist"

Run this FIRST, then re-run the complete SQL block above:

```sql
-- Create the ENUM types if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'test_booking_status') THEN
        CREATE TYPE test_booking_status AS ENUM ('PENDING', 'COMPLETED');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'test_result_status') THEN
        CREATE TYPE test_result_status AS ENUM ('PENDING', 'COMPLETED');
    END IF;
END $$;
```

### Error: "relation users does not exist"

Check if your users table exists:

```sql
SELECT table_name FROM information_schema.tables
WHERE table_name = 'users';
```

If it doesn't exist, you need to create the users table first.

---

## Summary

✅ Run the COMPLETE SQL block (Step 1)  
✅ Verify schema is correct (Step 2)  
✅ Restart backend (Step 3)  
✅ Test in app (Step 4)

**DO NOT** try to manually INSERT booking_id values!  
The database generates them automatically now! 🎉
