#!/bin/bash
podman run -d --name loki --pod logging-stack \
  -v $(pwd)/../loki-config.yaml:/etc/loki/loki-config.yaml \
  -v $(pwd)/../loki-data:/loki \
  grafana/loki:latest \
  -config.file=/etc/loki/loki-config.yaml
