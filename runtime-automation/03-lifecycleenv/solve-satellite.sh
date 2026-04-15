#!/bin/sh
# Create lifecycle environment "Test" in Satellite
# Corresponds to module-03: Create a Lifecycle Environment

hammer lifecycle-environment create \
  --name "Test" \
  --prior "Library" \
  --organization "Acme Org"
# Verify that the lifecycle environment was created
hammer lifecycle-environment list --organization "Acme Org"
