#!/bin/sh
# Solve module 08-iop-advisor
# Remediate advisor recommendations and update cvemap

ADMIN_PASSWORD="bc31c9a6-9ff0-11ec-9587-00155d1b0702"

echo "Solving module 08-iop-advisor" >> /tmp/progress.log

# Get host IDs for rhel1 and rhel2
# RHEL1_ID=$(hammer --no-headers --csv host list --search "name ~ rhel1" | head -1 | cut -d',' -f1)
# RHEL2_ID=$(hammer --no-headers --csv host list --search "name ~ rhel2" | head -1 | cut -d',' -f1)

echo "Host IDs: rhel1=$RHEL1_ID, rhel2=$RHEL2_ID" >> /tmp/progress.log

# # Remediate all advisor recommendations for rhel1 and rhel2
# # Get all recommendation IDs
# RECOMMENDATION_IDS=$(curl -s -k -u admin:${ADMIN_PASSWORD} \
#   https://satellite.lab/api/v2/rh_cloud/recommendations \
#   | python3 -c "import sys,json; data=json.load(sys.stdin); [print(r['id']) for r in data.get('results',[])]" 2>/dev/null)

# if [ -n "$RECOMMENDATION_IDS" ]; then
#   for REC_ID in $RECOMMENDATION_IDS; do
#     curl -s -k -u admin:${ADMIN_PASSWORD} \
#       -X PUT \
#       -H "Content-Type: application/json" \
#       -d "{\"host_ids\": [$RHEL1_ID, $RHEL2_ID]}" \
#       "https://satellite.lab/api/v2/rh_cloud/recommendations/$REC_ID/remediate" >> /tmp/progress.log 2>&1
#   done
#   echo "Remediated advisor recommendations" >> /tmp/progress.log
# else
#   echo "No advisor recommendations found, attempting UI-based remediation" >> /tmp/progress.log
#   # Trigger insights sync and remediation via hammer
#   hammer host ansible-roles play --id "$RHEL1_ID" 2>/dev/null
#   hammer host ansible-roles play --id "$RHEL2_ID" 2>/dev/null
# fi

# Download and install the CVE map
curl -o /root/cvemap.xml https://security.access.redhat.com/data/meta/v1/cvemap.xml
cp /root/cvemap.xml /var/lib/foreman/

echo "Updated cvemap.xml" >> /tmp/progress.log
echo "Solved module 08-iop-advisor" >> /tmp/progress.log
