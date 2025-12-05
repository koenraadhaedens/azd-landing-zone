#!/bin/bash

# Deploy API Application to VM
# This script should be run on the API VM after infrastructure deployment

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install .NET 8.0 if not already installed
if ! dotnet --version | grep -q "8.0"; then
    wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt-get update
    sudo apt-get install -y dotnet-sdk-8.0
fi

# Install Azure CLI if not already installed
if ! command -v az &> /dev/null; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Login using managed identity
az login --identity

# Create application directory
sudo mkdir -p /opt/apiapp
sudo chown $USER:$USER /opt/apiapp

# Copy application files (assumes files are already on the VM)
cp -r /tmp/apiapp/* /opt/apiapp/

# Build the application
cd /opt/apiapp
dotnet restore
dotnet build --configuration Release
dotnet publish --configuration Release --output ./publish

# Create systemd service file
sudo tee /etc/systemd/system/apiapp.service > /dev/null <<EOF
[Unit]
Description=API Application
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/dotnet /opt/apiapp/publish/ApiApp.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=apiapp
User=$USER
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:80
Environment=KeyVaultUri=$1

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable apiapp
sudo systemctl start apiapp

# Check service status
sudo systemctl status apiapp