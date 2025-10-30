@echo off
setlocal

:: --- Ensure administrator privileges ---
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Elevation required — relaunching as administrator...
    powershell -Command "Start-Process -FilePath '%comspec%' -ArgumentList '/c cd /d \"%~dp0\" && \"%~f0\"' -Verb RunAs"
    exit /b
)

echo =========================================
echo   UltraVNC Uninstall Script (Admin)
echo =========================================
echo.

:: --- Stop UltraVNC service if running ---
echo Stopping UltraVNC service if running...
sc query "uvnc_service" >nul 2>&1
if %errorlevel% equ 0 (
    net stop "uvnc_service" /y >nul 2>&1
    taskkill /f /im winvnc.exe >nul 2>&1
    echo UltraVNC stopped.
) else (
    echo UltraVNC service not found, skipping stop.
)
echo.

:: --- Uninstall and remove old files ---
echo Checking for UltraVNC installation...
if exist "%windir%\vnc\winvnc.exe" (
    echo Uninstalling UltraVNC service...
    "%windir%\vnc\winvnc.exe" -uninstall >nul 2>&1
    echo Removing UltraVNC directory...
    rmdir /s /q "%windir%\vnc"
    echo UltraVNC uninstalled successfully.
) else (
    echo UltraVNC not found, skipping uninstall.
)
echo.

:: --- Remove old firewall rules ---
echo Removing old firewall rules...
netsh advfirewall firewall delete rule name="VNC Allow Inbound" >nul 2>&1
netsh advfirewall firewall delete rule name="VNC Block Outbound" >nul 2>&1
echo Firewall rules removed.
echo.

echo =========================================
echo   UltraVNC Uninstallation Complete
echo =========================================
pause
endlocal
