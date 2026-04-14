!#/bin/bash

# Unregister Satellite server from itself.
subscription-manager unregister

# Delete Satellite from its inventory.
hammer host delete --name satellite.lab

# Delete the Activation Key created for the Satellite server.
hammer activation-key delete --name "Satellite Server" --organization "Acme Org"

# # Create an Activation Key for RHEL 10 content, which will be used by the RHEL 10 client system to register to Satellite and receive the RHEL 10 content.
# hammer activation-key create --name "RHEL10" --organization "Acme Org" --lifecycle-environment "Library" --content-view "Default Organization View"

# # Create a host registration script.
# SAT_HOST_REGISTRATION_SCRIPT=$(hammer host-registration generate-command \
#   --organization "Acme Org" \
#   --location "Vancouver" \
#   --activation-keys "RHEL10" \
#   --insecure true \
#   --force true \
#   --setup-insights true \
#   --setup-remote-execution true)

# ssh root@rhel1.lab bash -c "$SAT_HOST_REGISTRATION_SCRIPT"
# ssh root@rhel2.lab bash -c "$SAT_HOST_REGISTRATION_SCRIPT"
