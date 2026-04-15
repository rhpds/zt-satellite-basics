#!/bin/sh
# Create a host collection and install tmux on rhel1 and rhel2
# Corresponds to module-12: Install software

ORG="Acme Org"

# Create the host collection
hammer host-collection create \
  --name "TMUX installation" \
  --organization "$ORG"

# Add rhel1 and rhel2 to the host collection
hammer host-collection add-host \
  --name "TMUX installation" \
  --organization "$ORG" \
  --host-ids $(hammer --output csv --no-headers host list \
    --search "name = rhel1.lab or name = rhel2.lab" \
    --fields "Id" | paste -sd,)

# Install tmux on hosts in the host collection via remote execution
hammer job-invocation create \
  --feature katello_package_install \
  --search-query "host_collection = \"TMUX installation\"" \
  --inputs "package=tmux"

echo "tmux installed on rhel1 and rhel2" >> /tmp/progress.log
