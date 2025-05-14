# scripts/install.sh
#!/bin/bash

# Exit on any error
set -e

echo "Starting installation of logging stack prerequisites..."

# Update system and install required packages
echo "Installing Podman and git..."
dnf update -y
dnf install -y podman git

# Enable and start podman socket
echo "Enabling and starting podman socket..."
systemctl enable --now podman.socket

# Create necessary directories
echo "Creating directory structure..."
mkdir -p /opt/logging-stack/{config,data}
mkdir -p /opt/logging-stack/config/{fluent-bit,loki,grafana}
mkdir -p /opt/logging-stack/data/{loki,grafana,fluent-bit}

# Copy configuration files
echo "Copying configuration files..."
cp -r config/* /opt/logging-stack/config/
cp -r data/* /opt/logging-stack/data/

# Set up SELinux contexts if SELinux is enabled
if command -v sestatus >/dev/null 2>&1; then
    if sestatus | grep -q "SELinux status:.*enabled"; then
        echo "Configuring SELinux contexts..."
        chcon -R system_u:object_r:container_file_t:s0 /opt/logging-stack
    fi
fi

# Set up quadlet directory
echo "Setting up quadlet configuration..."
mkdir -p /etc/containers/systemd
cp /opt/logging-stack/config/*.container /etc/containers/systemd/
cp /opt/logging-stack/config/*.network /etc/containers/systemd/

# Reload systemd to recognize new units
echo "Reloading systemd..."
systemctl daemon-reload

echo "Installation completed successfully!"
echo "You can now run the deploy.sh script to start the logging stack."