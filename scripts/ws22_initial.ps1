# Check if the script is running with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    # If not running as admin, restart the script with elevated privileges
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Set execution policy to bypass for the current process and machine
# This allows the script to run without restrictions
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy Bypass -Scope LocalMachine -Force

# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Configure SSH service to start automatically and start it now
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

# Configure firewall rule to allow incoming SSH connections
$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

# Install Chocolatey package manager
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Refresh environment variables to include Chocolatey
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Python 3.12.0 using Chocolatey
choco install -y python --version=3.12.0

# Install specific Windows Features
$features = @('Web-Mgmt-Tools', 'Web-FTP-Server', 'WAS')
foreach ($feature in $features) {
    Install-WindowsFeature -Name $feature -IncludeAllSubFeature
}

# Install the latest version of NuGet package provider for PowerShell
Install-PackageProvider -Name NuGet -Force

# Install PSWindowsUpdate module and run Windows Update
Install-Module PSWindowsUpdate -Confirm:$false -Force
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot

# Restart the computer to apply changes
Restart-Computer -Force