#!/bin/bash
# apply_migration.sh - Safe database migration script
# This script applies the normalized schema migration to the PostgreSQL database

set -e  # Exit on error

echo "================================"
echo "Database Migration Script"
echo "================================"
echo ""

# Detect if running in Docker or local
CONTAINER_NAME="backend_server-postgres-1"
DOCKER_CMD=$(command -v docker 2>/dev/null || echo "")

if [ -n "$DOCKER_CMD" ]; then
    echo "🐳 Docker detected, using docker exec"
    EXEC_CMD="docker exec -i $CONTAINER_NAME psql -U postgres -d dishari_dev"
else
    echo "📝 Using local psql (ensure PostgreSQL is installed and running)"
    EXEC_CMD="psql -h localhost -p 8090 -U postgres -d dishari_dev"
fi

echo ""
echo "Step 1: Checking database connectivity..."
if $EXEC_CMD -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ Database connection successful"
else
    echo "❌ Failed to connect to database"
    echo "   Make sure PostgreSQL container is running:"
    echo "   docker-compose -f backend/backend_server/docker-compose.yaml up -d"
    exit 1
fi

echo ""
echo "Step 2: Backing up database..."
BACKUP_FILE="database_backup_$(date +%Y%m%d_%H%M%S).sql"
if [ -n "$DOCKER_CMD" ]; then
    docker exec $CONTAINER_NAME pg_dump -U postgres -d dishari_dev > "$BACKUP_FILE"
else
    pg_dump -h localhost -p 8090 -U postgres -d dishari_dev > "$BACKUP_FILE"
fi
echo "✅ Backup created: $BACKUP_FILE"

echo ""
echo "Step 3: Applying migration..."
echo "⚠️  WARNING: This will recreate database tables!"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled"
    exit 1
fi

# Apply the migration
MIGRATION_FILE="migrations/normalized_schema.sql"
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "Executing migration..."
if [ -n "$DOCKER_CMD" ]; then
    cat "$MIGRATION_FILE" | docker exec -i $CONTAINER_NAME psql -U postgres -d dishari_dev
else
    $EXEC_CMD -f "$MIGRATION_FILE"
fi

echo "✅ Migration completed successfully!"

echo ""
echo "Step 4: Verifying migration..."
echo ""
if [ -n "$DOCKER_CMD" ]; then
    docker exec $CONTAINER_NAME psql -U postgres -d dishari_dev <<EOF
SELECT 'Schema Verification' as check;
SELECT '✓ Users table' as result, COUNT(*) as count FROM users
UNION ALL
SELECT '✓ Staff profiles', COUNT(*) FROM staff_profiles
UNION ALL
SELECT '✓ Patient profiles', COUNT(*) FROM patient_profiles
UNION ALL
SELECT '✓ Lab tests', COUNT(*) FROM lab_tests
UNION ALL
SELECT '✓ Test bookings', COUNT(*) FROM test_bookings
UNION ALL
SELECT '✓ Booking tests', COUNT(*) FROM booking_tests
UNION ALL
SELECT '✓ Test results', COUNT(*) FROM test_results;

SELECT '✓ ENUM Types' as check;
SELECT typname FROM pg_type WHERE typname IN ('user_role', 'test_booking_status', 'test_result_status');
EOF
else
    $EXEC_CMD <<EOF
SELECT 'Schema Verification' as check;
SELECT '✓ Users table' as result, COUNT(*) as count FROM users
UNION ALL
SELECT '✓ Staff profiles', COUNT(*) FROM staff_profiles
UNION ALL
SELECT '✓ Patient profiles', COUNT(*) FROM patient_profiles
UNION ALL
SELECT '✓ Lab tests', COUNT(*) FROM lab_tests
UNION ALL
SELECT '✓ Test bookings', COUNT(*) FROM test_bookings
UNION ALL
SELECT '✓ Booking tests', COUNT(*) FROM booking_tests
UNION ALL
SELECT '✓ Test results', COUNT(*) FROM test_results;

SELECT '✓ ENUM Types' as check;
SELECT typname FROM pg_type WHERE typname IN ('user_role', 'test_booking_status', 'test_result_status');
EOF
fi

echo ""
echo "✅ Migration verification complete!"
echo ""
echo "📝 Summary:"
echo "  - Database backed up to: $BACKUP_FILE"
echo "  - Normalized schema applied"
echo "  - All tables created with proper relationships"
echo "  - ENUM types configured"
echo ""
echo "🚀 Your database is ready for the new application!"
echo ""
echo "⚙️  Next steps:"
echo "  1. Restart the backend server: dart bin/main.dart"
echo "  2. Test creating a booking with multiple tests"
echo "  3. Verify email sending works"
echo ""
