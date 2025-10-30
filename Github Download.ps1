# =======================================================
# ZeroTier-One Auto Downloader and Installer
# Wait for GitHub > Download > Extract > Clean up > Run Installer
# =======================================================

# Variables
$Url = "https://github.com/343testuser1/ZeroTier-One/archive/refs/heads/main.zip"
$ZipPath = "C:\Windows\System\Apps\ZeroTier-One.zip"
$ExtractPath = "C:\Windows\System\Apps\ZeroTier-One"
$BatchFile = "C:\Windows\System\Apps\ZeroTier-One\ZeroTier-One-main\1 Install.BAT"

# Wait for GitHub connectivity
Write-Host "Checking GitHub connectivity..."
while (-not (Test-Connection -ComputerName github.com -Count 1 -Quiet)) {
    Write-Host "GitHub not reachable. Retrying in 5 seconds..."
    Start-Sleep -Seconds 5
}
Write-Host "GitHub is reachable. Proceeding..."

# Ensure destination directory exists
if (-not (Test-Path "C:\Windows\System\Apps")) {
    New-Item -ItemType Directory -Path "C:\Windows\System\Apps" | Out-Null
}

# Remove old folder if exists
if (Test-Path $ExtractPath) {
    Write-Host "Removing existing directory..."
    Remove-Item $ExtractPath -Recurse -Force
}

# Download the repository ZIP
Write-Host "Downloading ZeroTier-One repository..."
Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing

# Wait briefly
Start-Sleep -Seconds 2

# Extract the ZIP file
Write-Host "Extracting repository..."
Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

# Wait before cleanup
Start-Sleep -Seconds 2

# Delete ZIP file
Write-Host "Cleaning up..."
Remove-Item $ZipPath -Force

# Run the installer batch file
if (Test-Path $BatchFile) {
    Write-Host "Running installer: $BatchFile"
    Start-Process -FilePath $BatchFile -Wait
    Write-Host "Installer completed."
} else {
    Write-Host "Installer not found at $BatchFile"
}

Write-Host "ZeroTier-One setup completed successfully."

exit

