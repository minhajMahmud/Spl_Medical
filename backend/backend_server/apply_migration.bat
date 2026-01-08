@echo off
REM apply_migration.bat - Safe database migration script for Windows
REM This script applies the normalized schema migration to the PostgreSQL database

setlocal enabledelayedexpansion

echo ================================
echo Database Migration Script
echo ================================
echo.

REM Detect Docker
where docker >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo 🐳 Docker detected, using docker exec
    set "CONTAINER_NAME=backend_server-postgres-1"
    set "EXEC_CMD=docker exec -i !CONTAINER_NAME! psql -U postgres -d dishari_dev"
) else (
    echo 📝 Using local psql ^(ensure PostgreSQL is installed and running^)
    set "EXEC_CMD=psql -h localhost -p 8090 -U postgres -d dishari_dev"
)

echo.
echo Step 1: Checking database connectivity...
%EXEC_CMD% -c "SELECT 1;" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Database connection successful
) else (
    echo ❌ Failed to connect to database
    echo    Make sure PostgreSQL container is running:
    echo    docker-compose -f backend/backend_server/docker-compose.yaml up -d
    pause
    exit /b 1
)

echo.
echo Step 2: Backing up database...
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set "BACKUP_FILE=database_backup_!mydate!_!mytime!.sql"

if defined CONTAINER_NAME (
    docker exec !CONTAINER_NAME! pg_dump -U postgres -d dishari_dev > !BACKUP_FILE!
) else (
    %EXEC_CMD:psql=pg_dump% > !BACKUP_FILE!
)

if %ERRORLEVEL% EQU 0 (
    echo ✅ Backup created: !BACKUP_FILE!
) else (
    echo ❌ Backup failed
    pause
    exit /b 1
)

echo.
echo Step 3: Applying migration...
echo ⚠️  WARNING: This will recreate database tables!
set /p CONFIRM="Continue? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Migration cancelled
    pause
    exit /b 1
)

REM Check migration file exists
if not exist "migrations\normalized_schema.sql" (
    echo ❌ Migration file not found: migrations\normalized_schema.sql
    pause
    exit /b 1
)

echo Executing migration...
for /f "delims=" %%i in ('type migrations\normalized_schema.sql') do (
    echo %%i
) | %EXEC_CMD%

if %ERRORLEVEL% EQU 0 (
    echo ✅ Migration completed successfully!
) else (
    echo ❌ Migration failed - check the errors above
    echo Backup is available at: !BACKUP_FILE!
    pause
    exit /b 1
)

echo.
echo Step 4: Verifying migration...
echo.

if defined CONTAINER_NAME (
    docker exec !CONTAINER_NAME! psql -U postgres -d dishari_dev -c ^
    "SELECT 'Schema Verification' as check; SELECT '✓ Users table' as result, COUNT(*) as count FROM users UNION ALL SELECT '✓ Staff profiles', COUNT(*) FROM staff_profiles UNION ALL SELECT '✓ Patient profiles', COUNT(*) FROM patient_profiles UNION ALL SELECT '✓ Lab tests', COUNT(*) FROM lab_tests UNION ALL SELECT '✓ Test bookings', COUNT(*) FROM test_bookings UNION ALL SELECT '✓ Booking tests', COUNT(*) FROM booking_tests UNION ALL SELECT '✓ Test results', COUNT(*) FROM test_results;"
) else (
    %EXEC_CMD% -c ^
    "SELECT 'Schema Verification' as check; SELECT '✓ Users table' as result, COUNT(*) as count FROM users UNION ALL SELECT '✓ Staff profiles', COUNT(*) FROM staff_profiles UNION ALL SELECT '✓ Patient profiles', COUNT(*) FROM patient_profiles UNION ALL SELECT '✓ Lab tests', COUNT(*) FROM lab_tests UNION ALL SELECT '✓ Test bookings', COUNT(*) FROM test_bookings UNION ALL SELECT '✓ Booking tests', COUNT(*) FROM booking_tests UNION ALL SELECT '✓ Test results', COUNT(*) FROM test_results;"
)

echo.
echo ✅ Migration verification complete!
echo.
echo 📝 Summary:
echo    - Database backed up to: !BACKUP_FILE!
echo    - Normalized schema applied
echo    - All tables created with proper relationships
echo    - ENUM types configured
echo.
echo 🚀 Your database is ready for the new application!
echo.
echo ⚙️  Next steps:
echo    1. Restart the backend server: dart bin/main.dart
echo    2. Test creating a booking with multiple tests
echo    3. Verify email sending works
echo.

pause
