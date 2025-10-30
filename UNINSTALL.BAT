@echo off
setlocal

:: Ensure Administrator Privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    PowerShell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo Uninstalling UltraVNC...
echo.

:: Stop UltraVNC Service if running
net stop "UltraVNC" >nul 2>&1

:: Uninstall UltraVNC service if present
if exist "%windir%\vnc\winvnc.exe" (
    "%windir%\vnc\winvnc.exe" -uninstall >nul 2>&1
)

:: Remove firewall rules
echo Removing firewall rules...
netsh advfirewall firewall delete rule name="VNC Allow Inbound" >nul 2>&1

netsh advfirewall firewall delete rule name="VNC Block Outbound" >nul 2>&1

:: Remove VNC folder
echo Deleting UltraVNC folder...
rd /s /q "%windir%\vnc" >nul 2>&1

echo.
echo UltraVNC Uninstalled Successfully.
pause
