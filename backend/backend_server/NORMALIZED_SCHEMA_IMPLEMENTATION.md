# Normalized Database Schema Implementation

## Overview

This document describes the normalized database schema implementation for the Dishari medical lab system with support for multiple tests per booking.

## Schema Changes

### New ENUM Types

```sql
CREATE TYPE user_role AS ENUM (
    'STUDENT','TEACHER','STAFF','DOCTOR','DISPENSER','LABSTAFF','ADMIN','OUTSIDE'
);

CREATE TYPE test_booking_status AS ENUM (
    'PENDING','COMPLETED'
);

CREATE TYPE test_result_status AS ENUM (
    'PENDING','COMPLETED'
);
```

### Tables

#### users

- **Purpose**: Central user registry for all system users
- **Key Fields**:
  - `user_id BIGSERIAL PRIMARY KEY` - Auto-incrementing user ID
  - `email VARCHAR(150) UNIQUE` - User email
  - `phone VARCHAR(20) UNIQUE NOT NULL` - User phone number
  - `role user_role` - User role (ENUM type)
  - `is_active BOOLEAN DEFAULT TRUE` - Account status
  - Timestamps: `created_at`, `updated_at`

#### staff_profiles

- **Purpose**: Staff-specific profile information
- **Key Fields**:
  - `user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE`
  - `specialization VARCHAR(100)` - Doctor/staff specialization
  - `qualification VARCHAR(100)` - Professional qualifications
  - `joining_date DATE` - Employment date

#### patient_profiles

- **Purpose**: Patient-specific profile information
- **Key Fields**:
  - `user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE`
  - `blood_group VARCHAR(10)` - Patient blood group
  - `allergies TEXT` - Patient allergies and sensitivities

#### lab_tests

- **Purpose**: Available lab tests registry
- **Key Fields**:
  - `test_id BIGSERIAL PRIMARY KEY` - Auto-incrementing test ID
  - `test_name VARCHAR(100)` - Test name
  - `description TEXT` - Test description
  - `student_fee NUMERIC(10,2)` - Fee for students
  - `staff_fee NUMERIC(10,2)` - Fee for staff
  - `outside_fee NUMERIC(10,2)` - Fee for external patients
  - `available BOOLEAN DEFAULT TRUE` - Availability status

#### test_bookings

- **Purpose**: Patient bookings for one or more tests
- **Key Fields**:
  - `booking_id BIGSERIAL PRIMARY KEY` - Auto-incrementing booking ID
  - `patient_id BIGINT REFERENCES users(user_id)` - Link to patient
  - `booking_date DATE DEFAULT CURRENT_DATE` - Date of booking
  - `is_external_patient BOOLEAN DEFAULT FALSE` - Walk-in patient flag
  - `status test_booking_status DEFAULT 'PENDING'` - Booking status
  - Timestamps: `created_at`, `updated_at`
- **Notes**: Support for external/walk-in patients without users table entry

#### booking_tests (Junction Table)

- **Purpose**: Links multiple tests to a single booking
- **Key Fields**:
  - `booking_test_id BIGSERIAL PRIMARY KEY` - Auto-incrementing record ID
  - `booking_id BIGINT REFERENCES test_bookings(booking_id) ON DELETE CASCADE`
  - `test_id BIGINT REFERENCES lab_tests(test_id)`
  - `UNIQUE (booking_id, test_id)` - Prevent duplicate test bookings
  - Timestamp: `created_at`
- **Purpose**: Enables one booking to contain multiple tests

#### test_results

- **Purpose**: Results for individual tests in a booking
- **Key Fields**:
  - `result_id BIGSERIAL PRIMARY KEY` - Auto-incrementing result ID
  - `booking_test_id BIGINT UNIQUE REFERENCES booking_tests(booking_test_id) ON DELETE CASCADE` - Links to specific test
  - `staff_id BIGINT REFERENCES users(user_id)` - Staff member who performed test
  - `status test_result_status DEFAULT 'PENDING'` - Result status
  - `result_date DATE` - Date when result was recorded
  - `attachment_path TEXT` - Path to result document/PDF
  - Timestamps: `created_at`, `updated_at`
- **Notes**: Each test in a booking gets its own result record

## Workflow

### Creating a Booking with Multiple Tests

1. Insert into `test_bookings` table - returns `booking_id`
2. For each test:
   - Insert into `booking_tests` table (booking_id + test_id)
   - Gets `booking_test_id` from junction table
3. Each `booking_test_id` can later have its own result

### Uploading Test Results

1. Identify the booking and test
2. Look up corresponding `booking_test_id` from `booking_tests` table
3. Insert/update in `test_results` table with reference to `booking_test_id`
4. When all tests in a booking have results with status='COMPLETED', mark booking as COMPLETED

### Querying Results for a Booking

```sql
SELECT
  tb.booking_id,
  bt.test_id,
  t.test_name,
  tr.status,
  tr.result_date,
  tr.attachment_path
FROM test_bookings tb
JOIN booking_tests bt ON tb.booking_id = bt.booking_id
JOIN lab_tests t ON bt.test_id = t.test_id
LEFT JOIN test_results tr ON bt.booking_test_id = tr.booking_test_id
WHERE tb.booking_id = ?
ORDER BY bt.booking_test_id;
```

## Backend Endpoint Changes

### createTestBooking()

- **New Behavior**: Inserts multiple tests in `booking_tests` junction table
- **Supports**: List of test IDs instead of single test
- **Flow**:
  1. Parse patient identifier (email/phone/user_id)
  2. Create booking in `test_bookings`
  3. Loop through test IDs and insert into `booking_tests`
  4. Returns true/false on success/failure

### uploadTestResult()

- **New Behavior**: Uploads result for individual test within a booking
- **Parameters**: Now accepts optional `testId` to specify which test
- **Flow**:
  1. Parse booking code (e.g., BK000123)
  2. Lookup corresponding `booking_test_id` for the test
  3. Insert/update in `test_results` table
  4. Check if all tests in booking are completed
  5. If all done, mark booking as COMPLETED
  6. Send result emails to patient and staff

## Migration Script

Run the SQL file at:

```
backend/backend_server/migrations/normalized_schema.sql
```

Or apply manually to PostgreSQL:

```bash
psql -h localhost -U postgres -d dishari_dev -f migrations/normalized_schema.sql
```

## Indexes for Performance

The migration creates indexes on frequently queried columns:

- `idx_users_email` - Email lookups
- `idx_users_phone` - Phone lookups
- `idx_users_role` - Role filtering
- `idx_test_bookings_patient_id` - Patient bookings
- `idx_test_bookings_booking_date` - Date range queries
- `idx_booking_tests_booking_id` - Tests per booking
- `idx_test_results_staff_id` - Staff results
- `idx_test_results_status` - Result status queries

## Backward Compatibility Notes

- The schema requires migration from old tables
- Existing booking codes (e.g., 'BK001') will still work as numeric IDs
- Email sending still works with new schema
- All external patient fields work the same way

## Testing

### Manual Test Flow

1. Create a booking with multiple tests:

   ```dart
   await backend.client.profile.createTestBooking(
     bookingId: 'BK001',
     testIds: [1, 2, 3],  // Multiple tests
     bookingDate: DateTime.now(),
   );
   ```

2. Upload result for first test:

   ```dart
   await backend.client.profile.uploadTestResult(
     bookingId: 'BK000001',  // Numeric ID returned from booking
     testId: '1',
     staffId: 'staff@email.com',
     status: 'COMPLETED',
     attachmentContentBase64: base64String,
   );
   ```

3. Upload result for second test - booking auto-marks as complete when all done

## Future Enhancements

- Add composite result view combining results from multiple tests
- Add bulk result upload
- Add result comparisons across multiple tests
- Add historical result queries per test
