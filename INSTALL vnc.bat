@echo off
setlocal

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    PowerShell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo Running with administrator privileges...
echo.

if exist "%windir%\vnc\winvnc.exe" (
    echo Stopping and uninstalling existing UltraVNC...
    net stop "UltraVNC" >nul 2>&1
    "%windir%\vnc\winvnc.exe" -uninstall >nul 2>&1
)

echo Removing old firewall rules...
netsh advfirewall firewall delete rule name="VNC Allow Inbound" >nul 2>&1

netsh advfirewall firewall delete rule name="VNC Block Outbound" >nul 2>&1

cd /d "%~dp0"

if not exist "%windir%\vnc" (
    md "%windir%\vnc"
)

echo Copying UltraVNC files...
copy /y "%~dp0*.*" "%windir%\vnc" >nul

echo Installing UltraVNC service...
"%windir%\vnc\winvnc.exe" -install

echo Adding firewall rules...
netsh advfirewall firewall add rule name="VNC Allow Inbound" dir=in action=allow protocol=TCP localport=5900 >nul

netsh advfirewall firewall add rule name="VNC Block Outbound" dir=out action=block protocol=TCP localport=5900 >nul

echo Starting UltraVNC service...
net start "UltraVNC" >nul 2>&1

echo.
echo UltraVNC Installation Complete.
pause
