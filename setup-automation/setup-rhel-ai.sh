#!/bin/bash

LOG=/tmp/setup-scripts/setup-rhel-ai.log
echo "starting setup-rhel-ai.sh" >> "$LOG"

# SSH to Satellite and create an admin Hammer access token for MCP. Satellite's
# services can still be coming up when setup runs, so retry instead of failing the
# whole lab. Use a unique token name so re-running setup never collides with an
# earlier token ("Name has already been taken").
FOREMAN_TOKEN=""
i=0
while [ "$i" -lt 24 ]; do
  i=$((i + 1))
  TOKEN_NAME="mcp server token $(date +%s)-$i"
  FOREMAN_TOKEN=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new satellite.lab \
    "hammer user access-token create --user=admin --name='$TOKEN_NAME'" 2>/dev/null | tail -1 | tr -d '\r')
  # A failed hammer call prints an error message instead of a token; only accept
  # a value that looks like an access token.
  echo "$FOREMAN_TOKEN" | grep -qE '^[A-Za-z0-9_-]{16,}$' || FOREMAN_TOKEN=""
  [ -n "$FOREMAN_TOKEN" ] && break
  echo "Waiting for Satellite hammer (attempt $i/24)" >> "$LOG"
  sleep 10
done
if [ -z "$FOREMAN_TOKEN" ]; then
  echo "WARNING: could not create Foreman access token; continuing without it" >> "$LOG"
fi

# Install OpenCode v2 for root. The lab terminal auto-logs in as root and root's PATH
# puts /root/.opencode/bin first, so this is the binary participants run. The image
# ships OpenCode 1 at that path, so the installer has to replace it in place.
# Note: v2 reports its version as "opencode v2.x.y", not just "v2.x.y".
