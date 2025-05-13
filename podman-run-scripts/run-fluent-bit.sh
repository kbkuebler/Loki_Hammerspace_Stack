#!/bin/bash
podman run -d --name fluentbit --pod logging-stack \
  -v $(pwd)/../fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf \
  -v $(pwd)/../parsers.conf:/fluent-bit/etc/parsers.conf \
  fluent/fluent-bit:latest \
  -c /fluent-bit/etc/fluent-bit.conf
