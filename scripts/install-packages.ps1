
# Ensure Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Verify Chocolatey installation
try {
    choco --version | Out-Null
} catch {
    Write-Error "Chocolatey failed to install"
    exit 1
}

# Install required packages
Write-Host "Installing packages..."
choco install nginx python visualstudio2022buildtools -y --force

# Add Nginx to system PATH
try {
    # Find the latest Nginx installation directory
    $nginxPath = Get-ChildItem -Path "C:\ProgramData\chocolatey\lib\nginx\tools\nginx-*" -Directory | 
                 Select-Object -First 1 -ExpandProperty FullName
    
    if ($nginxPath -and (Test-Path $nginxPath)) {
        # Add to current session PATH
        $env:Path += ";$nginxPath"
        
        # Persist PATH change for future sessions
        [Environment]::SetEnvironmentVariable(
            "Path", 
            "$env:Path", 
            [EnvironmentVariableTarget]::Machine
        )
        Write-Host "Nginx path added to system PATH"
    } else {
        Write-Warning "Nginx installation directory not found"
    }
} catch {
    Write-Error "Failed to update PATH: $_"
    exit 1
}

# Verify installations
Write-Host "Verifying installations..."
try {
    # Test Nginx
    if (Get-Command nginx -ErrorAction SilentlyContinue) {
        nginx -v
    } else {
        Write-Error "Nginx not found in PATH"
        exit 1
    }

    # Test Python
    python --version
    
    # Test Visual Studio Build Tools
    if (Get-Command cl.exe -ErrorAction SilentlyContinue) {
        cl.exe /?
    } else {
        Write-Warning "cl.exe (C++ compiler) not found in PATH"
    }
} catch {
    Write-Error "Verification failed: $_"
    exit 1
}

Write-Host "All packages installed successfully!"
