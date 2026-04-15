#!/bin/sh
# Add Satellite Client repo to content view, enable in activation key, install tracer
# Corresponds to module-09: Enable the Tracer service on RHEL hosts

ORG="Acme Org"

# Add Satellite Client 6 repository to the RHEL10 content view
hammer content-view add-repository \
  --name "RHEL10" \
  --organization "$ORG" \
  --product "Red Hat Enterprise Linux for x86_64" \
  --repository "Red Hat Satellite Client 6 for RHEL 10 x86_64 RPMs"

# Publish new version of the content view
hammer content-view publish \
  --name "RHEL10" \
  --organization "$ORG" \
  --description "Added the Satellite Client 6 repo."

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

# Override the Satellite Client 6 repo to Enabled in the RHEL10 activation key
hammer activation-key content-override \
  --name "RHEL10" \
  --organization "$ORG" \
  --content-label "satellite-client-6-for-rhel-10-x86_64-rpms" \
  --override-name "enabled" \
  --value 1

# Install tracer on rhel1 and rhel2 via remote execution
hammer job-invocation create \
  --job-template "Run Command - Script Default" \
  --search-query "name = rhel1.lab or name = rhel2.lab" \
  --inputs "command=dnf config-manager --set-enabled satellite-client-6-for-rhel-10-x86_64-rpms && dnf install -y katello-host-tools-tracer"

echo "Tracer installed on rhel1 and rhel2" >> /tmp/progress.log
