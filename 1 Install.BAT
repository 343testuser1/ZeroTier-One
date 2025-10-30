@@echo off
setlocal

:: --- Ensure administrator privileges ---
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Elevation required — relaunching as administrator...
    powershell -Command "Start-Process -FilePath '%comspec%' -ArgumentList '/c cd /d \"%~dp0\" && call \"INSTALL vnc.bat\"' -Verb RunAs"
    exit /b
)

:: --- Run INSTALL vnc.bat in same window ---
cd /d "%~dp0"
call "INSTALL vnc.bat"

endlocal


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

@echo off
:: =====================================================
:: Delete the ZeroTier-One scheduled task (requires admin)
:: =====================================================

:: Ensure admin privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrator privileges...
    PowerShell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

echo.
echo Deleting scheduled task "ZeroTier-One-Startup"...
schtasks /Delete /TN "ZeroTier-One-Startup" /F

echo.
echo Task deletion complete.

pause
