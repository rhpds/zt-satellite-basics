#!/bin/sh
# Create activation key for RHEL10 content view
# Corresponds to module-05: Create an Activation Key

ORG="Acme Org"

# Create the activation key associated with the Test lifecycle environment
# and the RHEL10 content view
hammer activation-key create \
  --name "RHEL10" \
  --lifecycle-environment "Test" \
  --content-view "RHEL10" \
  --organization "$ORG"
