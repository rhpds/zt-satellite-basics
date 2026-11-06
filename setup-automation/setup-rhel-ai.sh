#!/bin/bash

echo "starting setup-rhel-ai.sh" >> /tmp/setup-scripts/setup-rhel-ai.log

# SSH to Satellite, create an admin Hammer access token for MCP. Use a unique token
# name: re-running setup must not collide with the token created by a previous run
# ("Name has already been taken"), and an empty token would silently break the MCP server.
TOKEN_NAME="mcp server token $(date +%s)"
export FOREMAN_TOKEN=$(ssh satellite.lab "hammer user access-token create --user=admin --name='$TOKEN_NAME'" | tail -1)
if [ -z "$FOREMAN_TOKEN" ]; then
  echo "ERROR: could not create Foreman access token" >> /tmp/setup-scripts/setup-rhel-ai.log
  exit 1
fi

# Install OpenCode v2 for root. The lab terminal auto-logs in as root and root's PATH
# puts /root/.opencode/bin first, so this is the binary participants run. The image
# ships OpenCode 1 at that path, so the installer has to replace it in place.
# Note: v2 reports its version as "opencode v2.x.y", not just "v2.x.y".
OC_BIN=/root/.opencode/bin/opencode
if ! "$OC_BIN" --version 2>/dev/null | grep -q 'v2\.'; then
  echo "Installing OpenCode v2 for root" >> /tmp/setup-scripts/setup-rhel-ai.log
  timeout 600 curl -fsSL https://opencode.ai/v2/install -o /tmp/opencode-v2-install.sh
  HOME=/root timeout 600 bash /tmp/opencode-v2-install.sh --no-modify-path \
    >> /tmp/setup-scripts/setup-rhel-ai.log 2>&1
fi

# The installer unpacks through /tmp, which can leave the binary labelled user_tmp_t.
# Reset it to the policy default for /root.
restorecon -v "$OC_BIN" >> /tmp/setup-scripts/setup-rhel-ai.log 2>&1 || true

if ! "$OC_BIN" --version 2>/dev/null | grep -q 'v2\.'; then
  echo "ERROR: OpenCode v2 is not installed; aborting" >> /tmp/setup-scripts/setup-rhel-ai.log
  exit 1
fi
OC_VERSION=$("$OC_BIN" --version 2>/dev/null)
echo "Using $OC_VERSION" >> /tmp/setup-scripts/setup-rhel-ai.log

# The lab is terminal-only now. Remove the web interface unit left behind by
# earlier versions of this script so it cannot crash-loop on an existing deployment.
if [ -f /etc/systemd/system/opencode.service ]; then
  systemctl disable --now opencode.service >> /tmp/setup-scripts/setup-rhel-ai.log 2>&1 || true
  rm -f /etc/systemd/system/opencode.service
  systemctl daemon-reload
fi

# Persist OpenCode v2 configuration: default model plus the MCP servers (heredoc unquoted
# so $FOREMAN_TOKEN is substituted; the \$schema dollar sign is escaped).
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
