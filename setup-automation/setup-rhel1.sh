#!/bin/bash

dnf remove -y tmux
systemctl stop dnf-automatic-install.timer
systemctl disable dnf-automatic-install.timer
systemctl mask dnf-automatic-install.timer

# Trigger vulnerability - downgrade packages with known CVEs
dnf downgrade -y gnutls 2>/dev/null || true
dnf install -y tar-1.35-8.el10_1 --allowerasing 2>/dev/null || dnf downgrade -y tar 2>/dev/null || true