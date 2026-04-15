#!/bin/sh
echo "Starting module called 14-satellite-ai-integration" >> /tmp/progress.log

# Trigger vulnerability - downgrade packages with known CVEs
dnf downgrade -y gnutls 2>/dev/null || true
dnf install -y tar-1.35-8.el10_1 --allowerasing 2>/dev/null || dnf downgrade -y tar 2>/dev/null || true

echo "Security misconfigurations applied to rhel1" >> /tmp/progress.log
