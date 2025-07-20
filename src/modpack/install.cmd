@echo off
setlocal enabledelayedexpansion

echo ╔══════════════════════════════════════════════╗
echo ║        deep.space.10 Modpack Installer       ║
echo ╚══════════════════════════════════════════════╝

set "VALHEIM_DIR=%USERPROFILE%\AppData\LocalLow\IronGate\Valheim"
set "INSTALL_DIR=%~dp0"

echo Checking Valheim installation...

if not exist "%VALHEIM_DIR%" (
    echo ERROR: Valheim directory not found. Please run Valheim at least once.
    pause
    exit /b 1
)

echo Installing BepInEx...
if exist "%INSTALL_DIR%\BepInEx" (
    xcopy /E /I /Y "%INSTALL_DIR%\BepInEx" "%VALHEIM_DIR%\..\..\..\steamapps\common\Valheim\BepInEx"
)

echo Installing mods...
if exist "%INSTALL_DIR%\mods" (
    xcopy /E /I /Y "%INSTALL_DIR%\mods\*" "%VALHEIM_DIR%\..\..\..\steamapps\common\Valheim\BepInEx\plugins\"
)

echo Installing configs...
if exist "%INSTALL_DIR%\config" (
    xcopy /E /I /Y "%INSTALL_DIR%\config\*" "%VALHEIM_DIR%\..\..\..\steamapps\common\Valheim\BepInEx\config\"
)

echo Installation complete!
echo Please restart Valheim to load the mods.
pause