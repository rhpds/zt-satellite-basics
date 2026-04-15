#!/bin/sh
# Create content view, add repositories, publish and promote
# Corresponds to module-04: Create a Content View

ORG="Acme Org"

# Create the content view
hammer content-view create \
  --name "RHEL10" \
  --organization "$ORG"

# Add BaseOS repository
hammer content-view add-repository \
  --name "RHEL10" \
  --organization "$ORG" \
  --product "Red Hat Enterprise Linux for x86_64" \
  --repository "Red Hat Enterprise Linux 10 for x86_64 - BaseOS RPMs 10"

# Add AppStream repository
hammer content-view add-repository \
  --name "RHEL10" \
  --organization "$ORG" \
  --product "Red Hat Enterprise Linux for x86_64" \
  --repository "Red Hat Enterprise Linux 10 for x86_64 - AppStream RPMs 10"

# Publish the content view
hammer content-view publish \
  --name "RHEL10" \
  --organization "$ORG"

# Get the latest version ID and promote to the Test lifecycle environment
VERSION_ID=$(hammer --output csv --no-headers content-view version list \
  --content-view "RHEL10" \
  --organization "$ORG" \
  --order "version DESC" \
  --per-page 1 \
  --fields "Id" | head -1)

hammer content-view version promote \
  --id "$VERSION_ID" \
  --to-lifecycle-environment "Test" \
  --organization "$ORG"
