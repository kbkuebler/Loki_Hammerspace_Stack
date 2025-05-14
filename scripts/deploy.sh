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
podman network create logging-stack

# Start the containers
echo "Starting containers..."
podman run -d --name loki --network logging-stack \
    -v /opt/logging-stack/config/loki/loki-config.yaml:/etc/loki/loki-config.yaml:ro \
    -v /opt/logging-stack/data/loki:/loki \
    -p 3100:3100 \
    grafana/loki:latest \
    -config.file=/etc/loki/loki-config.yaml

podman run -d --name fluentbit --network logging-stack \
    -v /opt/logging-stack/config/fluent-bit/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf:ro \
    -v /opt/logging-stack/config/fluent-bit/parsers.conf:/fluent-bit/etc/parsers.conf:ro \
    -p 514:514/udp \
    -p 2020:2020 \
    fluent/fluent-bit:latest \
    -c /fluent-bit/etc/fluent-bit.conf

podman run -d --name grafana --network logging-stack \
    -v /opt/logging-stack/config/grafana/datasources.yaml:/etc/grafana/provisioning/datasources/datasources.yaml:ro \
    -v /opt/logging-stack/data/grafana:/var/lib/grafana \
    -p 3000:3000 \
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
podman ps