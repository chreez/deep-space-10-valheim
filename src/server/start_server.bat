@echo off
setlocal enabledelayedexpansion

echo Starting deep.space.10 Valheim Server...

set "SERVER_DIR=%~dp0"
set "CONFIG_FILE=%SERVER_DIR%\server_config.json"

if not exist "%CONFIG_FILE%" (
    echo ERROR: Server config file not found at %CONFIG_FILE%
    pause
    exit /b 1
)

cd /d "%SERVER_DIR%"

valheim_server.exe ^
    -name "deep.space.10" ^
    -port 27500 ^
    -world "DeepSpace10" ^
    -password "changeme123" ^
    -public 0 ^
    -savedir "%SERVER_DIR%\worlds" ^
    -backups 3 ^
    -backupshort 7200 ^
    -backuplong 43200 ^
    -crossplay

pause