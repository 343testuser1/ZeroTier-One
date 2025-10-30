# ===============================================
# FullSetup.ps1
# Complete ZeroTier + Firewall + Power Settings Setup
# ===============================================

# Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator."
    exit
}

function Run-Section {
    param (
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host "----------------------------------------------------"
    Write-Host "Running section: $Name"
    Write-Host "----------------------------------------------------"

    $attempt = 1
    while ($true) {
        try {
            & $Action
            Write-Host "$Name completed successfully on attempt $attempt"
            break
        }
        catch {
            Write-Host "$Name failed on attempt $attempt"
            Write-Host "Error: $($_.Exception.Message)"
            Write-Host "Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
            $attempt++
        }
    }
}

# ===============================================
# Section 1: Install ZeroTier One (loop until success)
# ===============================================
$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Installer = Join-Path $CurrentDir "ZeroTier One.msi"

while ($true) {
    Write-Host "Installing ZeroTier One from $Installer ..."
    $process = Start-Process msiexec.exe -ArgumentList "/i `"$Installer`" /quiet /norestart" -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "ZeroTier One installation completed successfully."
        break
    }

    Write-Host "Install failed. Retrying..."
    Start-Sleep -Seconds 3
}

# ===============================================
# Section 2: Allow All Firewall Rules
# ===============================================
Run-Section "Allow All Firewall Rules" {
    if (-not (Get-NetFirewallRule -DisplayName "Allow All Inbound" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "Allow All Inbound" -Direction Inbound -Action Allow -Protocol Any -Profile Any
    }

    if (-not (Get-NetFirewallRule -DisplayName "Allow All Outbound" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "Allow All Outbound" -Direction Outbound -Action Allow -Protocol Any -Profile Any
    }

    if (-not (Get-NetFirewallRule -DisplayName "Allow VNC over ZeroTier" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "Allow VNC over ZeroTier" -Direction Inbound -Protocol TCP -LocalPort 5900 -Action Allow -Profile Any
    }
}

# ===============================================
# Section 3: ZeroTier Firewall Rules
# ===============================================
Run-Section "ZeroTier Firewall Rules" {
    $app = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe"
    if (!(Test-Path $app)) { throw "ZeroTier executable not found" }

    if (-not (Get-NetFirewallRule -DisplayName "ZeroTier One - Inbound" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "ZeroTier One - Inbound" -Direction Inbound -Program $app -Action Allow -Profile Any | Out-Null
    }

    if (-not (Get-NetFirewallRule -DisplayName "ZeroTier One - Outbound" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "ZeroTier One - Outbound" -Direction Outbound -Program $app -Action Allow -Profile Any | Out-Null
    }
}

# ===============================================
# Section 4: ZeroTier Service Cleanup & Start
# ===============================================
Run-Section "ZeroTier Service Cleanup & Start" {
    Stop-Process -Name "zerotier_desktop_ui" -Force -ErrorAction SilentlyContinue
    if ((Get-Service "ZeroTier One").Status -ne "Running") {
        Start-Service "ZeroTier One"
    }
}

# ===============================================
# Section 5: Rename ZeroTier Adapter
# ===============================================
Run-Section "Rename ZeroTier Adapter" {
    for ($i = 1; $i -le 10; $i++) {
        $adapter = Get-NetAdapter | Where-Object {
            $_.Name -like "*ZeroTier*" -or $_.InterfaceDescription -like "*ZeroTier*"
        } | Select-Object -First 1
        if ($adapter) { break }
        Start-Sleep -Seconds 2
    }

    if (!$adapter) { throw "ZeroTier adapter not detected after 10 tries" }

    if ($adapter.Name -ne "Ethernet 4") {
        Write-Host "Renaming $($adapter.Name) to Ethernet 4"
        netsh interface set interface name="$($adapter.Name)" newname="Ethernet 4"
        Start-Sleep -Milliseconds 600
    }
}

# ===============================================
# Section 6: Power Settings Configuration
# ===============================================
Run-Section "Power Settings Configuration" {
    powercfg -change standby-timeout-ac 0
    powercfg -change standby-timeout-dc 0
    powercfg -change monitor-timeout-ac 20
    powercfg -change monitor-timeout-dc 20
}

# ===============================================
# Section 7: Hide ZeroTier from Apps & Features
# ===============================================
Run-Section "Hide ZeroTier from Apps & Features" {
    $RegPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ZeroTier One 1.16.0"

    if (Test-Path $RegPath) {
        Set-ItemProperty -Path $RegPath -Name "SystemComponent" -Value 1 -Type DWord
        Write-Host "ZeroTier One 1.16.0 is now hidden from Apps & Features."
    } else {
        Write-Host "Registry key not found: $RegPath"
    }
}

# ===============================================
# Section 8: ZeroTier Network Join (moved last)
# ===============================================
Run-Section "ZeroTier Network Join" {
    $env:PATH += ";C:\ProgramData\ZeroTier\One"
    zerotier-cli join 4753cf475f50f9f1
    Start-Sleep -Seconds 5

    for ($i = 1; $i -le 10; $i++) {
        if ((zerotier-cli info) -match "ONLINE") { return }
        Start-Sleep -Seconds 3
    }
    throw "ZeroTier did not come online"
}

Write-Host "All setup tasks completed successfully."
