# 🔧 Quick Fix - Apply Schema Patch Immediately

## Problem

Database still has old schema (VARCHAR(20) booking_id), backend expects BIGSERIAL.

## Solution - Run ONE of These

### 🪟 Windows - EASIEST (Double-Click)

```
backend\backend_server\quick_fix.bat
```

Takes 5 seconds. Done!

### 🐳 Docker Command

```bash
cd backend/backend_server
docker exec -i backend_server-postgres-1 psql -U postgres -d dishari_dev < migrations/quick_fix.sql
```

### 📝 Manual psql

```bash
cd backend/backend_server
psql -h localhost -p 8090 -U postgres -d dishari_dev -f migrations/quick_fix.sql
```

## What It Does

✅ Converts `booking_id` from VARCHAR(20) to BIGSERIAL  
✅ Creates `booking_tests` junction table  
✅ Updates `test_results` table structure  
✅ Creates ENUM types  
✅ Adds performance indexes  
✅ Backs up old data

## After Fix

Restart backend:

```bash
cd backend/backend_server
dart bin/main.dart
```

Test in app:

- Create booking with multiple tests
- Upload results
- Verify working

## That's It!

Your database is now updated. The backend code will work. 🚀
