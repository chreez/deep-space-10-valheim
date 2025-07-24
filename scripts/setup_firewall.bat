@echo off
REM Valheim Server Firewall Setup
REM This batch file configures Windows Firewall for Valheim Server ports

echo Setting up Windows Firewall for Valheim Server...
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as Administrator"
    pause
    exit /b 1
)

REM Remove existing rules
echo Removing any existing Valheim firewall rules...
netsh advfirewall firewall delete rule name="Valheim Server Port 27500" >nul 2>&1
netsh advfirewall firewall delete rule name="Valheim Server Port 27501" >nul 2>&1
netsh advfirewall firewall delete rule name="Valheim Server Port 27502" >nul 2>&1

REM Add inbound rules
echo.
echo Creating inbound firewall rules...

netsh advfirewall firewall add rule name="Valheim Server Port 27500" ^
    dir=in action=allow protocol=UDP localport=27500 ^
    description="Valheim game server main port"

netsh advfirewall firewall add rule name="Valheim Server Port 27501" ^
    dir=in action=allow protocol=UDP localport=27501 ^
    description="Valheim server query port"

netsh advfirewall firewall add rule name="Valheim Server Port 27502" ^
    dir=in action=allow protocol=UDP localport=27502 ^
    description="Valheim Steam integration port"

REM Add outbound rules
echo.
echo Creating outbound firewall rules...

netsh advfirewall firewall add rule name="Valheim Server Port 27500" ^
    dir=out action=allow protocol=UDP localport=27500 ^
    description="Valheim game server main port"

netsh advfirewall firewall add rule name="Valheim Server Port 27501" ^
    dir=out action=allow protocol=UDP localport=27501 ^
    description="Valheim server query port"

netsh advfirewall firewall add rule name="Valheim Server Port 27502" ^
    dir=out action=allow protocol=UDP localport=27502 ^
    description="Valheim Steam integration port"

REM Show the created rules
echo.
echo Verifying firewall rules...
netsh advfirewall firewall show rule name="Valheim Server Port 27500"
netsh advfirewall firewall show rule name="Valheim Server Port 27501"
netsh advfirewall firewall show rule name="Valheim Server Port 27502"

echo.
echo Firewall configuration complete!
echo.
echo NOTE: Don't forget to configure port forwarding on your router:
echo   - Forward ports 27500-27502 UDP to this machine's IP address
echo.
pause