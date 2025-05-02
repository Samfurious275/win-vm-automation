# Ensure script runs with elevated permissions
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator."
    exit 1
}

# Step 1: Install Chocolatey (if not already installed)
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Step 2: Download and Install .NET Framework 4.8
$dotNetInstallerPath = "$env:TEMP\ndp48-x86-x64-allos-enu.exe"
Write-Host "Downloading .NET Framework 4.8..."
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile('https://download.visualstudio.microsoft.com/download/pr/2d6bb6b2-226a-4baa-bdec-798822606ff1/8494001c276a4b96804cde7829c04d7f/ndp48-x86-x64-allos-enu.exe', $dotNetInstallerPath)

Write-Host "Installing .NET Framework 4.8..."
$process = Start-Process -FilePath $dotNetInstallerPath -ArgumentList "/q /norestart" -Wait -PassThru
if ($process.ExitCode -notin @(0, 3010)) {
    Write-Error ".NET Framework installation failed with exit code: $($process.ExitCode)"
    exit 1
}

# Step 3: Reboot the VM (required for .NET installation)
Write-Host "Rebooting the VM to complete .NET Framework installation..."
Restart-Computer -Force

# Step 4: Wait for the VM to come back online
Start-Sleep -Seconds 120  # Adjust based on VM boot time

# Step 5: Reconnect and Install Packages (this will run after reboot)
# Reconfigure WinRM to persist after reboot
winrm quickconfig -quiet
Set-Item WSMan:\localhost\Client\AllowUnencrypted $true -Force
Set-Item WSMan:\localhost\Client\Auth\Basic $true -Force

# Install Python and Nginx via Chocolatey
Write-Host "Installing Python and Nginx..."
choco install python nginx -y --force

# Add Nginx to system PATH
try {
    $nginxPath = Get-ChildItem -Path "C:\ProgramData\chocolatey\lib\nginx\tools\nginx-*" -Directory | Select-Object -First 1 -ExpandProperty FullName
    if ($nginxPath -and (Test-Path $nginxPath)) {
        $env:Path += ";$nginxPath"
        [Environment]::SetEnvironmentVariable("Path", "$env:Path", [EnvironmentVariableTarget]::Machine)
        Write-Host "Nginx path added to system PATH"
    } else {
        Write-Error "Nginx installation directory not found"
        exit 1
    }
} catch {
    Write-Error "Failed to update PATH: $_"
    exit 1
}

# Verify installations
Write-Host "Verifying installations..."
try {
    if (Get-Command nginx -ErrorAction SilentlyContinue) { nginx -v } else { Write-Error "Nginx not found in PATH"; exit 1 }
    python --version
} catch {
    Write-Error "Verification failed: $_"
    exit 1
}
