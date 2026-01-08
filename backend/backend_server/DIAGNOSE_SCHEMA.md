# Diagnose Your Database Schema

The error `uploadTestResult: booking not found` means your database schema is incompatible. Run these checks in **pgAdmin4 Query Tool** to verify your current schema.

## Check 1: test_bookings table structure

```sql
\d test_bookings
```

**Expected Output:**

```
Column         |    Type     |
---------------+-------------+
booking_id     | bigint      |  ← Should be BIGINT, NOT VARCHAR(20)
patient_id     | bigint      |
booking_date   | date        |
is_external... | boolean     |
status         | USER-DEFINED (test_booking_status)
created_at     | timestamp   |
updated_at     | timestamp   |
```

**If booking_id is VARCHAR(20)**: ❌ Schema is OLD, needs fix

---

## Check 2: booking_tests junction table exists

```sql
\d booking_tests
```

**Expected Output:**

```
Column          |    Type     |
----------------+-------------+
booking_test_id | bigint      |
booking_id      | bigint      |
test_id         | bigint      |
created_at      | timestamp   |
```

**If table doesn't exist**: ❌ Table missing, needs fix

---

## Check 3: test_results references booking_test_id

```sql
\d test_results
```

**Expected Output:**

```
Column          |    Type     | Modifiers
----------------+-------------+--------------------------------------
result_id       | bigint      |
booking_test_id | bigint      | not null unique ← Should reference JUNCTION table
staff_id        | bigint      |
status          | USER-DEFINED (test_result_status)
result_date     | date        |
attachment_path | text        |
created_at      | timestamp   |
updated_at      | timestamp   |
```

**If it references booking_id instead**: ❌ Schema is OLD, needs fix

---

## If Any Check Failed

👉 **Follow the fix in [FIX_IN_PGADMIN.md](FIX_IN_PGADMIN.md)**

Then re-run these checks to verify all are correct ✅

---

## Quick Health Check

Run all at once:

```sql
-- Check 1: booking_id column type
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'test_bookings' AND column_name = 'booking_id';

-- Check 2: junction table exists
SELECT table_name FROM information_schema.tables
WHERE table_name = 'booking_tests';

-- Check 3: test_results foreign key
SELECT constraint_name, column_name
FROM information_schema.key_column_usage
WHERE table_name = 'test_results' AND constraint_type = 'FOREIGN KEY';
```

**Expected Results:**

```
Column 1 - booking_id should be "bigint" (NOT "character varying")
Column 2 - Should show "booking_tests"
Column 3 - Should show "booking_test_id" (NOT "booking_id")
```

If all are correct ✅, restart backend and test again.
