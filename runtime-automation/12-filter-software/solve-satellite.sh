#!/bin/sh
# Create a content view filter to exclude emacs, publish and promote
# Corresponds to module-12: Filter content

ORG="Acme Org"

# Create an exclude filter for emacs on the RHEL10 content view
hammer content-view filter create \
  --name "emacs" \
  --content-view "RHEL10" \
  --organization "$ORG" \
  --type "rpm" \
  --inclusion false \
  --description "added emacs filter"

# Add an RPM rule to exclude all versions of emacs
hammer content-view filter rule create \
  --content-view "RHEL10" \
  --content-view-filter "emacs" \
  --organization "$ORG" \
  --name "emacs"

# Publish new version of the content view
hammer content-view publish \
  --name "RHEL10" \
  --organization "$ORG" \
  --description "added emacs filter"

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

echo "Emacs filter applied to RHEL10 content view" >> /tmp/progress.log
