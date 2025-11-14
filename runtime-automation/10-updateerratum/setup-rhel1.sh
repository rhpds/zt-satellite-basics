#!/bin/sh
echo "Starting module called 09-updateerratum" >> /tmp/progress.log

dnf downgrade -y polkit
