#!/bin/bash
podman pod create --name logging-stack -p 3100:3100 -p 514:514/udp -p 3000:3000
