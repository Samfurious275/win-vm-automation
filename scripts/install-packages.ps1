# Install Nginx
choco install nginx -y

# Install Python 3
choco install python -y

# Install Visual Studio Build Tools (C++)
choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64" -y

# Optional: Verify installations
nginx -v
python --version
cl.exe /?
