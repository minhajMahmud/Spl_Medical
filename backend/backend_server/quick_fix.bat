@echo off
REM quick_fix.bat - Apply minimal SQL patch to fix schema immediately
REM This script converts VARCHAR(20) booking_id to BIGSERIAL

setlocal enabledelayedexpansion

echo ====================================
echo Quick Schema Fix
echo ====================================
echo.

REM Check if Docker is available
where docker >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Using Docker...
    set "CONTAINER_NAME=backend_server-postgres-1"
    
    REM Check if container is running
    docker ps | find "!CONTAINER_NAME!" >nul
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ Docker container not running
        echo Start with: docker-compose -f backend/backend_server/docker-compose.yaml up -d
        pause
        exit /b 1
    )
    
    echo ✅ Container found
    echo.
    echo Applying quick fix SQL...
    
    for /f "delims=" %%i in ('type migrations\quick_fix.sql') do (
        echo %%i
    ) | docker exec -i !CONTAINER_NAME! psql -U postgres -d dishari_dev
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ✅ Schema fix applied successfully!
        echo.
        echo Database is now ready for the new code.
        echo.
        echo Next: Restart backend with: dart bin/main.dart
    ) else (
        echo ❌ SQL execution failed
        pause
        exit /b 1
    )
) else (
    echo ❌ Docker not found
    echo.
    echo Run this command instead:
    echo docker exec -i backend_server-postgres-1 psql -U postgres -d dishari_dev ^< migrations\quick_fix.sql
    pause
    exit /b 1
)

pause
