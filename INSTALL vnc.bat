@echo off
setlocal enabledelayedexpansion

:: --- Ensure administrator privileges ---
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Elevation required — relaunching as administrator...
    powershell -Command "Start-Process -FilePath '%comspec%' -ArgumentList '/c cd /d \"%~dp0\" && \"%~f0\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo =========================================
echo   UltraVNC Silent Install Script (Admin)
echo =========================================
echo.

:: --- Step 1: Stop any running UltraVNC service ---
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

:: --- Step 2: Uninstall and remove old files ---
echo Checking for existing UltraVNC installation...
if exist "%windir%\vnc\winvnc.exe" (
    echo Uninstalling existing UltraVNC...
    "%windir%\vnc\winvnc.exe" -uninstall >nul 2>&1
    echo Removing old UltraVNC directory...
    rmdir /s /q "%windir%\vnc"
    echo Old UltraVNC removed.
) else (
    echo No previous UltraVNC found, skipping uninstall.
)
echo.

:: --- Step 3: Remove old firewall rules ---
echo Removing old firewall rules...
netsh advfirewall firewall delete rule name="VNC Allow Inbound" >nul 2>&1
netsh advfirewall firewall delete rule name="VNC Block Outbound" >nul 2>&1
echo Old firewall rules removed.
echo.

:: --- Step 4: Copy new files ---
echo Copying UltraVNC files...
if not exist "%windir%\vnc" mkdir "%windir%\vnc"
copy /y "%~dp0winvnc.exe" "%windir%\vnc" >nul
copy /y "%~dp0vnchooks.dll" "%windir%\vnc" >nul
copy /y "%~dp0ultravnc.ini" "%windir%\vnc" >nul
echo Files copied successfully.
echo.

:: --- Step 5: Install service ---
echo Installing UltraVNC service...
"%windir%\vnc\winvnc.exe" -install >nul 2>&1
echo UltraVNC service installed.
echo.

:: --- Step 6: Add firewall rules ---
echo Adding firewall rules...
netsh advfirewall firewall add rule name="VNC Allow Inbound" dir=in action=allow protocol=TCP localport=5900 >nul
netsh advfirewall firewall add rule name="VNC Block Outbound" dir=out action=block protocol=TCP localport=5900 >nul
echo Firewall rules added.
echo.

:: --- Step 7: Start service ---
echo Starting UltraVNC service...
net start "UltraVNC" >nul 2>&1
echo UltraVNC service started.
echo.

echo =========================================
echo   UltraVNC Installation Complete
echo =========================================
endlocal
