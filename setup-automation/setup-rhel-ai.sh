#!/bin/bash

LOG=/tmp/setup-scripts/setup-rhel-ai.log
echo "starting setup-rhel-ai.sh" >> "$LOG"

# SSH to Satellite and create an admin Hammer access token for MCP. Satellite's
# services can still be coming up when setup runs, so retry instead of failing the
# whole lab. Use a unique token name so re-running setup never collides with an
# earlier token ("Name has already been taken").
FOREMAN_TOKEN=""
i=0
while [ "$i" -lt 12 ]; do
  i=$((i + 1))
  TOKEN_NAME="mcp server token $(date +%s)-$i"
  FOREMAN_TOKEN=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new satellite.lab \
    "hammer user access-token create --user=admin --name='$TOKEN_NAME'" 2>/dev/null | tail -1)
  [ -n "$FOREMAN_TOKEN" ] && break
  echo "Waiting for Satellite hammer (attempt $i/12)" >> "$LOG"
  sleep 10
done
if [ -z "$FOREMAN_TOKEN" ]; then
  echo "WARNING: could not create Foreman access token; continuing without it" >> "$LOG"
fi

# Install OpenCode v2 for root. The lab terminal auto-logs in as root and root's PATH
# puts /root/.opencode/bin first, so this is the binary participants run. The image
# ships OpenCode 1 at that path, so the installer has to replace it in place.
# Note: v2 reports its version as "opencode v2.x.y", not just "v2.x.y".
OC_BIN=/root/.opencode/bin/opencode
oc_is_v2() {
  "$OC_BIN" --version 2>/dev/null | grep -qE '(^|v)2\.'
}

if ! oc_is_v2; then
  echo "Installing OpenCode v2 for root" >> "$LOG"
  for attempt in 1 2; do
    if timeout 600 curl -fsSL https://opencode.ai/v2/install -o /tmp/opencode-v2-install.sh \
       && HOME=/root timeout 600 bash /tmp/opencode-v2-install.sh --no-modify-path >> "$LOG" 2>&1 \
       && oc_is_v2; then
      break
    fi
    echo "OpenCode v2 install attempt $attempt failed" >> "$LOG"
    sleep 10
  done
fi

OC_V2=1
if ! oc_is_v2; then
  OC_V2=0
  echo "WARNING: OpenCode v2 is not available; the AI module will be degraded" >> "$LOG"
else
  # The installer unpacks through /tmp, which can leave the binary labelled user_tmp_t.
  restorecon -v "$OC_BIN" >> "$LOG" 2>&1 || true
  OC_VERSION=$("$OC_BIN" --version 2>/dev/null)
  echo "Using $OC_VERSION" >> "$LOG"
fi

# The lab is terminal-only now. Remove the web interface unit left behind by
# earlier versions of this script so it cannot crash-loop on an existing deployment.
if [ -f /etc/systemd/system/opencode.service ]; then
  systemctl disable --now opencode.service >> "$LOG" 2>&1 || true
  rm -f /etc/systemd/system/opencode.service
  systemctl daemon-reload
fi

# Persist the OpenCode v2 configuration only when v2 is actually installed; a v2
# config makes the v1 binary fail to start ("Invalid input mcp.servers").
if [ "$OC_V2" = 1 ]; then
  # Heredoc is unquoted so $FOREMAN_TOKEN is substituted; \$schema is escaped.
  mkdir -p /root/.config/opencode/
  cat > /root/.config/opencode/opencode.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "opencode/glm-5.3-flash-free",
  "mcp": {
    "servers": {
      "satellite-mcp": {
        "type": "remote",
        "url": "http://localhost:8080/mcp",
        "oauth": false,
        "headers": {
          "FOREMAN_USERNAME": "admin",
          "FOREMAN_TOKEN": "$FOREMAN_TOKEN"
        }
      },
      "rhel-mcp": {
        "type": "local",
        "command": ["/usr/local/bin/linux-mcp-server","--no-verify-host-keys"]
      }
    }
  }
}
EOF
else
  rm -f /root/.config/opencode/opencode.json
fi

# Download the Foreman raw CA certificate and save it to /root/foreman_raw_ca (using -k to ignore SSL issues since it's a self-signed cert, and using the internal Satellite FQDN).
curl -k -o /root/foreman_raw_ca https://satellite.lab/unattended/public/foreman_raw_ca

# Write quadlet container unit file and start the satellite-mcp container.
mkdir -p /etc/containers/systemd/
cat > /etc/containers/systemd/satellite-mcp.container << 'EOF'
[Unit]
Description=Satellite MCP Container

[Container]
ContainerName=satellite-mcp
Image=docker.io/library/test:test
PublishPort=8080:8080
Volume=/root/foreman_raw_ca:/app/ca.pem:ro,Z
Exec=--foreman-url https://satellite.lab --allowed-rex-features "katello_errata_install,katello_package_install" --allowed-cv-actions "publish,promote,incremental_update"

[Service]
Restart=always

[Install]
WantedBy=multi-user.target default.target
EOF

systemctl daemon-reload
systemctl start satellite-mcp.service
