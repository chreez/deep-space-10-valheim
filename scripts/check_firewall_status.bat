@echo off
REM Check Windows Firewall status for Valheim ports

echo ========================================
echo Valheim Server Firewall Status Check
echo ========================================
echo.

REM Check if Windows Firewall is enabled
echo Checking Windows Firewall status...
netsh advfirewall show allprofiles | findstr "State"
echo.

REM Check for Valheim-specific rules
echo Checking for Valheim firewall rules...
echo.
echo INBOUND RULES:
netsh advfirewall firewall show rule name=all | findstr /i "valheim\|27500\|27501\|27502" | findstr /i "Rule Name\|LocalPort\|Action\|Direction"
echo.
echo OUTBOUND RULES:
netsh advfirewall firewall show rule name=all dir=out | findstr /i "valheim\|27500\|27501\|27502" | findstr /i "Rule Name\|LocalPort\|Action\|Direction"

echo.
echo ========================================
echo Port Listening Status:
echo ========================================
netstat -an | findstr ":27500\|:27501\|:27502"

echo.
echo ========================================
echo Quick Fix Commands:
echo ========================================
echo If rules are missing, run setup_firewall.bat as Administrator
echo.
pause