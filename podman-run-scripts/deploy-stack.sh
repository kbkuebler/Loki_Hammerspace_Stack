#!/bin/bash

# Exit on any error
set -e

# Configuration
POD_NAME="logging-stack"
CONFIG_DIR="$(pwd)"
DATA_DIR="${CONFIG_DIR}/data"

# Create necessary directories
mkdir -p "${DATA_DIR}/loki"

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
    if podman pod exists $POD_NAME; then
        echo "Removing existing pod: $POD_NAME"
        podman pod rm -f $POD_NAME
    fi
}

# Cleanup existing resources
echo "Cleaning up existing resources..."
cleanup_container "loki"
cleanup_container "fluentbit"
cleanup_container "grafana"
cleanup_pod

# Create the pod
echo "Creating pod: $POD_NAME"
podman pod create --name $POD_NAME \
    -p 3100:3100 \
    -p 514:514/udp \
    -p 3000:3000

# Start Loki
echo "Starting Loki..."
podman run -d --name loki --pod $POD_NAME \
    -v "${CONFIG_DIR}/loki-config.yaml:/etc/loki/loki-config.yaml" \
    -v "${DATA_DIR}/loki:/loki" \
    grafana/loki:latest \
    -config.file=/etc/loki/loki-config.yaml

# Start Fluent Bit
echo "Starting Fluent Bit..."
podman run -d --name fluentbit --pod $POD_NAME \
    -v "${CONFIG_DIR}/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf" \
    -v "${CONFIG_DIR}/parsers.conf:/fluent-bit/etc/parsers.conf" \
    fluent/fluent-bit:latest \
    -c /fluent-bit/etc/fluent-bit.conf

# Start Grafana
echo "Starting Grafana..."
podman run -d --name grafana --pod $POD_NAME \
    -v "${DATA_DIR}/grafana:/var/lib/grafana" \
    grafana/grafana:latest

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
podman ps --pod $POD_NAME
