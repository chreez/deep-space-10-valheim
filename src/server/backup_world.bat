@echo off
setlocal enabledelayedexpansion

set "SERVER_DIR=%~dp0"
set "WORLDS_DIR=%SERVER_DIR%\worlds"
set "BACKUP_DIR=%SERVER_DIR%\..\..\backups"
set "TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"

echo Creating world backup...

if not exist "%WORLDS_DIR%" (
    echo ERROR: Worlds directory not found at %WORLDS_DIR%
    pause
    exit /b 1
)

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

powershell -command "Compress-Archive -Path '%WORLDS_DIR%\*' -DestinationPath '%BACKUP_DIR%\world_%TIMESTAMP%.zip' -Force"

if %errorlevel% equ 0 (
    echo Backup created successfully: world_%TIMESTAMP%.zip
) else (
    echo ERROR: Backup failed
)

pause