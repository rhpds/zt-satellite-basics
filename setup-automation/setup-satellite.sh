!#/bin/bash

# Unregister Satellite server from itself.
subscription-manager unregister

# Delete Satellite from its inventory.
hammer host delete --name satellite.lab

# Delete the Activation Key created for the Satellite server.
hammer activation-key delete --name "Satellite Server" --organization "Acme Org"
