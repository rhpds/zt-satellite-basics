#!/bin/sh
# Register rhel1 and rhel2 to Satellite
# Corresponds to module-07: Register Hosts

# Generate the registration command
REGISTRATION_SCRIPT=$(hammer host-registration generate-command \
  --hostgroup "Application Servers" \
  --insecure 1 \
  --setup-insights 1 \
  --force 1)

# Register rhel1
ssh -o StrictHostKeyChecking=no root@rhel1 $REGISTRATION_SCRIPT

# Register rhel2
ssh -o StrictHostKeyChecking=no root@rhel2 $REGISTRATION_SCRIPT

echo "Registered rhel1 and rhel2 to Satellite" >> /tmp/progress.log
