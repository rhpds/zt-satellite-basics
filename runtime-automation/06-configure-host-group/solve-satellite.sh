#!/bin/sh
# Create and configure a host group with firewall system role
# Corresponds to module-06: Configure a Host Group

ORG="Acme Org"

# Create the host group
hammer hostgroup create \
  --name "Application Servers" \
  --lifecycle-environment "Test" \
  --content-view "RHEL10" \
  --content-source "satellite.lab" \
  --organization "$ORG"

# Assign the rhel-system-roles.firewall Ansible role
hammer hostgroup ansible-roles assign \
  --name "Application Servers" \
  --ansible-roles "rhel-system-roles.firewall"

# Assign the RHEL10 activation key
hammer hostgroup set-parameter \
  --hostgroup "Application Servers" \
  --name "kt_activation_keys" \
  --parameter-type "string" \
  --value "RHEL10"

# Add the firewall parameter to allow port 80/tcp
hammer hostgroup set-parameter \
  --hostgroup "Application Servers" \
  --name "firewall" \
  --parameter-type "array" \
  --value '[{"port":["80/tcp"],"state":"enabled"}]'
