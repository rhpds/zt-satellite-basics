#!/bin/sh
# Apply all installable errata to rhel1 and rhel2, then resolve traces
# Corresponds to module-10: Update Errata

for HOST in rhel1.lab rhel2.lab; do
  echo "Listing applicable errata for ${HOST}..." >> /tmp/progress.log

  ERRATA_IDS=$(hammer --output csv --no-headers host errata list \
    --host "$HOST" \
    --fields "Erratum ID" | paste -sd, -)

  if [ -z "$ERRATA_IDS" ]; then
    echo "No applicable errata found for ${HOST}" >> /tmp/progress.log
    continue
  fi

  echo "Applying errata to ${HOST}: ${ERRATA_IDS}" >> /tmp/progress.log

  hammer job-invocation create \
    --feature katello_errata_install \
    --inputs "errata=${ERRATA_IDS}" \
    --search-query "name = ${HOST}"
done


# Resolve traces on rhel1 via remote execution
hammer job-invocation create \
  --feature katello_host_tracer_resolve \
  --search-query "name = rhel1.lab"

# Resolve traces on rhel2 via remote execution
hammer job-invocation create \
  --feature katello_host_tracer_resolve \
  --search-query "name = rhel2.lab"

echo "Errata applied and traces resolved" >> /tmp/progress.log
