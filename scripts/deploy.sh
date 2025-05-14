# deploy.sh
#!/bin/bash

# Exit on any error
set -e

echo "Starting deployment of logging stack..."

# Function to check if a container exists and remove it
cleanup_container() {
    local container_name=$1
    if podman container exists $container_name; then
        echo "Removing existing container: $container_name"
        podman rm -f $container_name
    fi
}

# Function to check if pod exists and remove it
cleanup_pod() {
    if podman pod exists logging-stack; then
        echo "Removing existing pod: logging-stack"
        podman pod rm -f logging-stack
    fi
}

# Cleanup existing resources
echo "Cleaning up existing resources..."
cleanup_container "loki"
cleanup_container "fluentbit"
cleanup_container "grafana"
cleanup_pod

# Start the network
echo "Starting network..."
systemctl start logging-stack

# Start the containers
echo "Starting containers..."
systemctl start loki.container
systemctl start fluent-bit.container
systemctl start grafana.container

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 5

# Print status
echo "Stack deployment completed!"
echo "Services are available at:"
echo "Grafana: http://localhost:3000"
echo "Loki: http://localhost:3100"
echo "Fluent Bit metrics: http://localhost:2020"

# Print container status
echo -e "\nContainer Status:"
podman ps --pod logging-stack

# Set up quadlet directory
echo "Setting up quadlet configuration..."
mkdir -p /etc/containers/systemd

# Copy and rename container and network files
echo "Installing quadlet configurations..."
cp /opt/logging-stack/config/fluent-bit/fluent-bit.container /etc/containers/systemd/
cp /opt/logging-stack/config/loki/loki.container /etc/containers/systemd/
cp /opt/logging-stack/config/grafana/grafana.container /etc/containers/systemd/
cp /opt/logging-stack/config/logging-stack.network /etc/containers/systemd/

# Reload systemd to recognize new units
echo "Reloading systemd..."
systemctl daemon-reload