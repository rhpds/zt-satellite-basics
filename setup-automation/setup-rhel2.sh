#!/bin/bash
dnf remove -y tmux
systemctl stop dnf-automatic-install.timer
systemctl disable dnf-automatic-install.timer
systemctl mask dnf-automatic-install.timer

systemctl stop dnf-automatic.timer
systemctl disable dnf-automatic.timer
