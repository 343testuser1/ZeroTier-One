@echo off
setlocal enabledelayedexpansion
=========================================================

:: Ensure administrator privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    PowerShell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

:: ------------------------------------------------------------
:: STEP 1: Run PowerShell script (ZeroTier-One-Startup.ps1)
:: ------------------------------------------------------------
set "SCRIPT=%~dp0ZeroTier-One-Startup.ps1"

if not exist "%SCRIPT%" (
    echo ERROR: Cannot find "%SCRIPT%"
    echo Make sure ZeroTier-One-Startup.ps1 is in the same folder.
    exit /b 1
)

echo.
echo Running PowerShell script: %SCRIPT%
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

:: ------------------------------------------------------------
:: Done
:: ------------------------------------------------------------
echo.
echo Setup complete. Exiting...

pause

exit /b 0
