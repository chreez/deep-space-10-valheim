@echo off
echo Stopping deep.space.10 Valheim Server...

taskkill /f /im valheim_server.exe 2>nul
if %errorlevel% equ 0 (
    echo Server stopped successfully.
) else (
    echo No server process found.
)

pause