# =======================================================
# Setup Script: Save ZeroTier-One.ps1 and schedule to run at every system startup (SYSTEM user)
# =======================================================

$MainScriptPath = "C:\Windows\System\Apps\ZeroTier-One.ps1"
$TaskName = "ZeroTier-One-Startup"

# Ensure destination folder exists
if (-not (Test-Path "C:\Windows\System\Apps")) {
    New-Item -ItemType Directory -Path "C:\Windows\System\Apps" | Out-Null
}

# -------------------------------------------------------
# Write the main ZeroTier-One.ps1 script
# -------------------------------------------------------
$ScriptContent = @'
# =======================================================
# ZeroTier-One Auto Downloader and Installer
# Wait for GitHub > Download > Extract > Clean up > Run Installer
# =======================================================

$Url = "https://github.com/343testuser1/ZeroTier-One/archive/refs/heads/main.zip"
$ZipPath = "C:\Windows\System\Apps\ZeroTier-One.zip"
$ExtractPath = "C:\Windows\System\Apps\ZeroTier-One"
$BatchFile = "C:\Windows\System\Apps\ZeroTier-One\ZeroTier-One-main\1 Install.BAT"

Write-Host "Checking GitHub connectivity..."
while (-not (Test-Connection -ComputerName github.com -Count 1 -Quiet)) {
    Write-Host "GitHub not reachable. Retrying in 5 seconds..."
    Start-Sleep -Seconds 5
}
Write-Host "GitHub reachable. Proceeding..."

if (-not (Test-Path "C:\Windows\System\Apps")) {
    New-Item -ItemType Directory -Path "C:\Windows\System\Apps" | Out-Null
}

if (Test-Path $ExtractPath) {
    Write-Host "Removing existing directory..."
    Remove-Item $ExtractPath -Recurse -Force
}

Write-Host "Downloading repository..."
Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing

Start-Sleep -Seconds 2

Write-Host "Extracting repository..."
Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

Start-Sleep -Seconds 2

Write-Host "Cleaning up..."
Remove-Item $ZipPath -Force

if (Test-Path $BatchFile) {
    Write-Host "Running installer: $BatchFile"
    Start-Process -FilePath $BatchFile -Wait
    Write-Host "Installer completed."
} else {
    Write-Host "Installer not found at $BatchFile"
}

Write-Host "ZeroTier-One setup completed."
'@

# Save the main PowerShell file
Set-Content -Path $MainScriptPath -Value $ScriptContent -Encoding UTF8 -Force
Write-Host "Saved main script to $MainScriptPath"

# -------------------------------------------------------
# Create Scheduled Task (run at startup, SYSTEM account)
# -------------------------------------------------------
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$MainScriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

Write-Host "Scheduled task '$TaskName' created successfully to run at every system startup."
