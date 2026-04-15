#!/bin/sh
# Apply all installable errata to rhel1 and rhel2, then resolve traces
# Corresponds to module-10: Update Errata

# Apply all installable errata to rhel1 and rhel2 via remote execution
hammer job-invocation create \
  --feature katello_errata_install \
  --search-query "name = rhel1.lab or name = rhel2.lab" \
  --inputs "errata=all"

# Resolve traces on rhel1 via remote execution
hammer job-invocation create \
  --feature katello_host_tracer_resolve \
  --search-query "name = rhel1.lab"

# Resolve traces on rhel2 via remote execution
hammer job-invocation create \
  --feature katello_host_tracer_resolve \
  --search-query "name = rhel2.lab"

echo "Errata applied and traces resolved" >> /tmp/progress.log
