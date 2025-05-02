# Step 3: Reconfigure WinRM to persist after reboot
winrm quickconfig -quiet
Set-Item WSMan:\localhost\Client\AllowUnencrypted $true -Force
Set-Item WSMan:\localhost\Client\Auth\Basic $true -Force

# Step 4: Install Python and Nginx
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

Write-Host "Installing Python and Nginx..."
choco install python nginx -y --force

# Step 5: Add Nginx to system PATH
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

# Step 6: Verify installations
try {
    if (Get-Command nginx -ErrorAction SilentlyContinue) { nginx -v } else { Write-Error "Nginx not found in PATH"; exit 1 }
    python --version
} catch {
    Write-Error "Verification failed: $_"
    exit 1
}
