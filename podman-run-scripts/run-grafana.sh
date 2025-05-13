#!/bin/bash
podman run -d --name grafana --pod logging-stack \
  grafana/grafana:latest
