# Step 1: Install .NET Framework 4.8
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

# Step 2: Reboot the VM
Write-Host "Rebooting the VM to complete .NET Framework installation..."
Restart-Computer -Force
