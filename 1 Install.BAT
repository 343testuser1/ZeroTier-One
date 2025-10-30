@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: VNC + ZeroTier Setup Script
:: - Runs in same window
:: - Waits for VNC port 5900
:: - Runs PowerShell script
:: - No pauses, auto exit
:: ============================================================

:: Ensure administrator privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    PowerShell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

:: ------------------------------------------------------------
:: STEP 1: Run INSTALL vnc.BAT (ignore internal pause)
:: ------------------------------------------------------------
echo Running INSTALL vnc.BAT...
findstr /v /i "pause" "INSTALL vnc.BAT" > "%temp%\vnc_no_pause.bat"
call "%temp%\vnc_no_pause.bat"
del "%temp%\vnc_no_pause.bat" >nul 2>&1

:: ------------------------------------------------------------
:: STEP 2: Wait for VNC port 5900 to be listening
:: ------------------------------------------------------------
echo.
echo Waiting for VNC (port 5900) to start listening...

:wait_vnc
netstat -ano | findstr ":5900" | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo VNC is now running on port 5900.
) else (
    timeout /t 5 /nobreak >nul
    goto wait_vnc
)

:: ------------------------------------------------------------
:: STEP 3: Run PowerShell script (Join-ZeroTier.ps1)
:: ------------------------------------------------------------
set "SCRIPT=%~dp0Join-ZeroTier.ps1"

if not exist "%SCRIPT%" (
    echo ERROR: Cannot find "%SCRIPT%"
    echo Make sure Join-ZeroTier.ps1 is in the same folder.
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
exit /b 0
