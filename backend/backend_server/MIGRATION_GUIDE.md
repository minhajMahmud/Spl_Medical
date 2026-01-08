# Database Migration Instructions

## Quick Start - Apply the Migration

Your database needs to be updated to use the new normalized schema. There are two migration files:

### Option 1: Fresh Migration (Recommended for Development)

Use this if you don't have important data to preserve:

```bash
# Using Docker
docker exec -i backend_server-postgres-1 psql -U postgres -d dishari_dev < migrations/normalized_schema.sql

# Or directly with psql if PostgreSQL is installed
psql -h localhost -p 8090 -U postgres -d dishari_dev -f migrations/normalized_schema.sql
```

**This migration:**

- ✅ Drops all old tables (test_results, booking_tests, test_bookings, etc.)
- ✅ Creates fresh normalized schema with BIGSERIAL IDs
- ✅ Creates ENUM types for roles and statuses
- ✅ Creates all necessary indexes

### Option 2: Safe Migration (With Backup)

Use this if you have data to preserve:

```bash
# Using Docker
docker exec -i backend_server-postgres-1 psql -U postgres -d dishari_dev < migrations/safe_schema_migration.sql

# Or directly with psql
psql -h localhost -p 8090 -U postgres -d dishari_dev -f migrations/safe_schema_migration.sql
```

**This migration:**

- ✅ Renames old tables to \*\_old (backup)
- ✅ Creates new normalized tables
- ✅ Allows data migration (commented out by default)
- ⚠️ Requires manual cleanup of old tables after verification

## Verification After Migration

After applying the migration, verify it worked:

```bash
# Connect to database
docker exec -it backend_server-postgres-1 psql -U postgres -d dishari_dev

# Check tables exist
\dt

# Check ENUM types
\dT+ user_role
\dT+ test_booking_status
\dT+ test_result_status

# Sample query to verify schema
SELECT
  tb.booking_id,
  bt.booking_test_id,
  bt.test_id,
  t.test_name
FROM test_bookings tb
LEFT JOIN booking_tests bt ON tb.booking_id = bt.booking_id
LEFT JOIN lab_tests t ON bt.test_id = t.test_id
LIMIT 5;
```

## Database Connection Details

Default connection string in Docker:

```
Host: postgres (or localhost)
Port: 8090
Database: dishari_dev
User: postgres
Password: (check docker-compose.yaml or .env)
```

## Schema Overview

### Key Tables:

1. **users** - Central user registry with BIGSERIAL ID
2. **staff_profiles** - Staff-specific data
3. **patient_profiles** - Patient-specific data
4. **lab_tests** - Available tests with pricing
5. **test_bookings** - Bookings with BIGSERIAL ID
6. **booking_tests** - Junction table (one booking → multiple tests)
7. **test_results** - Individual results per test

### Key Change from Old Schema:

**OLD:**

```
test_bookings:
  booking_id VARCHAR(20) PRIMARY KEY  ← Only 20 chars, single test per booking
  test_id INT

test_results:
  booking_id VARCHAR(20) UNIQUE  ← Only one result per booking
```

**NEW:**

```
test_bookings:
  booking_id BIGSERIAL PRIMARY KEY  ← Auto-increment, supports scaling

booking_tests:  ← NEW JUNCTION TABLE
  booking_test_id BIGSERIAL PRIMARY KEY
  booking_id BIGINT
  test_id BIGINT

test_results:
  booking_test_id BIGINT UNIQUE  ← References junction table
  staff_id BIGINT
```

## Troubleshooting

### Error: "null value in column booking_id violates not-null constraint"

**Cause:** Old table schema still exists, new code expects BIGSERIAL
**Solution:** Run the migration (Option 1 or 2 above)

### Error: "type user_role does not exist"

**Cause:** ENUM types weren't created
**Solution:** Ensure the full migration ran successfully. Check with `\dT+`

### Error: "relation booking_tests does not exist"

**Cause:** Junction table not created (old schema only had test_bookings)
**Solution:** Run the migration - the junction table is new

## Rollback (if needed)

If using Safe Migration (Option 2), you can rollback:

```bash
docker exec -i backend_server-postgres-1 psql -U postgres -d dishari_dev <<EOF
-- Restore old tables
ALTER TABLE users RENAME TO users_new;
ALTER TABLE users_old RENAME TO users;

ALTER TABLE staff_profiles RENAME TO staff_profiles_new;
ALTER TABLE staff_profiles_old RENAME TO staff_profiles;

-- etc. for other tables

-- Then drop new tables or keep them as backup
EOF
```

## Backend Code Update

The backend code has already been updated to:

1. ✅ Accept multiple test IDs in `createTestBooking()`
2. ✅ Use `booking_test_id` in `uploadTestResult()`
3. ✅ Auto-complete booking when all tests are done
4. ✅ Handle BIGSERIAL ID generation

No code changes needed - just apply the database migration!

## Next Steps

1. **Backup your database** (if it has data)
2. **Run the migration** (choose Option 1 or 2)
3. **Verify** the schema with the checks above
4. **Test the app** - create a booking, add tests, upload results
5. **Monitor logs** for any issues
