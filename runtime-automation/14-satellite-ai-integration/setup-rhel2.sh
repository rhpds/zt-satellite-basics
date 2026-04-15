#!/bin/sh
echo "Starting module called 14-satellite-ai-integration" >> /tmp/progress.log

# Trigger vulnerability - install packages with known CVEs
# openssl-3.5.1-4.el10_1 is vulnerable to RHSA-2026:1472 (CVE-2025-11187, CVE-2025-15467, CVE-2025-15468, CVE-2026-22795, CVE-2026-22796)
dnf install -y openssl-3.5.1-4.el10_1 openssl-libs-3.5.1-4.el10_1 --allowerasing 2>/dev/null || true

# libvpx-1.14.1-4.el10 is vulnerable to RHSA-2026:4629 (CVE-2026-2447 - heap buffer overflow)
dnf install -y libvpx-1.14.1-4.el10 --allowerasing 2>/dev/null || true

echo "Security misconfigurations applied to rhel2" >> /tmp/progress.log

