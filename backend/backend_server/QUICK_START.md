# 🚀 Quick Start - Apply Database Migration

## ⚠️ Problem

Database error: `null value in column "booking_id" violates not-null constraint`

**Reason:** Backend code expects new schema, database still has old schema

## ✅ Solution (Choose ONE)

### 🪟 Windows Users - EASIEST

Simply double-click:

```
backend\backend_server\apply_migration.bat
```

That's it! The script handles everything.

### 🐧 Linux/Mac Users

Run one command:

```bash
bash backend/backend_server/apply_migration.sh
```

### 🐳 Docker Users (Any OS)

Copy and paste:

```bash
cd backend/backend_server
docker exec -i backend_server-postgres-1 psql -U postgres -d dishari_dev < migrations/normalized_schema.sql
```

### 📝 Manual psql

```bash
cd backend/backend_server
psql -h localhost -p 8090 -U postgres -d dishari_dev -f migrations/normalized_schema.sql
```

## ⏱️ Time Required

- Execution: **1-2 seconds**
- Backup creation: **Automatic**
- Verification: **Automatic**

## 🔄 What Happens

1. ✅ Database backed up automatically
2. ✅ Old tables renamed (\_old suffix)
3. ✅ New normalized schema created
4. ✅ ENUM types configured
5. ✅ Indexes created
6. ✅ Verification run

## 🎯 After Migration

Restart backend and test:

```bash
cd backend/backend_server
dart bin/main.dart
```

Then in Flutter:

1. Create a booking
2. Add multiple tests
3. Upload results
4. Check emails sent

## 📋 Files Updated

| File                                  | Purpose                       |
| ------------------------------------- | ----------------------------- |
| `normalized_schema.sql`               | Fresh migration (recommended) |
| `safe_schema_migration.sql`           | Safe backup version           |
| `apply_migration.bat`                 | Windows batch script          |
| `apply_migration.sh`                  | Linux/Mac bash script         |
| `README_MIGRATION.md`                 | Quick reference               |
| `MIGRATION_GUIDE.md`                  | Detailed guide                |
| `NORMALIZED_SCHEMA_IMPLEMENTATION.md` | Schema docs                   |

## ❓ Troubleshooting

**Docker not running?**

```bash
cd backend/backend_server
docker-compose up -d
```

**psql not found?**
Use Docker method above or install PostgreSQL CLI tools

**Something went wrong?**
Backup was created automatically - contact support with backup filename

## 🎓 What Changed

### Old Schema

- `test_bookings.booking_id` → VARCHAR(20)
- Single test per booking
- No junction table

### New Schema

- `test_bookings.booking_id` → BIGSERIAL (auto-increment)
- Multiple tests per booking via `booking_tests` junction table
- Individual results per test via `test_results.booking_test_id`
- Better scalability & data integrity

## 🚀 You're Ready!

Pick your method above and run the migration. Takes less than a minute!

Questions? See `MIGRATION_GUIDE.md` for detailed instructions.
