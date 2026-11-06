#!/bin/bash

echo "starting setup-rhel-ai.sh" >> /tmp/setup-scripts/setup-rhel-ai.log

# SSH to Satellite, create admin Hammer access token for MCP.
export FOREMAN_TOKEN=$(ssh satellite.lab 'hammer user access-token create --user=admin --name="mcp server token"' | tail -1)

# Upgrade opencode to v2 (--major is the documented V1 -> V2 path). Guard against re-runs,
# never block on input, and log a failure instead of stopping the rest of the setup.
if ! /root/.opencode/bin/opencode --version 2>/dev/null | grep -qE '^v?2\.'; then
  timeout 600 /root/.opencode/bin/opencode upgrade --major \
    </dev/null >> /tmp/setup-scripts/setup-rhel-ai.log 2>&1 \
    || echo "WARNING: opencode upgrade --major failed; continuing" >> /tmp/setup-scripts/setup-rhel-ai.log
fi

# Persist OpenCode v2 configuration: default model plus the MCP servers (heredoc unquoted
# so $FOREMAN_TOKEN is substituted; the \$schema dollar sign is escaped).
mkdir -p /root/.config/opencode/
cat > /root/.config/opencode/opencode.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "opencode/nemotron-3-ultra-free",
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

# Persist the OpenCode API key for the opencode provider when one was supplied.
if [ -n "$OPENCODE_API_KEY" ]; then
  mkdir -p /root/.local/share/opencode/
  cat > /root/.local/share/opencode/auth.json << EOF
{
  "opencode": {
    "type": "api",
    "key": "$OPENCODE_API_KEY"
  }
}
EOF
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

# Install and start OpenCode web interface systemd unit.
cat > /etc/systemd/system/opencode.service << 'EOF'
[Unit]
Description=OpenCode Web Interface
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/root/.opencode/bin/opencode serve --port 9999 --hostname 0.0.0.0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chcon -t bin_t /root/.opencode/bin/opencode
semanage fcontext -a -t bin_t '/root/.opencode/bin(/.*)?'
restorecon -Rv /root/.opencode/bin/

systemctl daemon-reload
systemctl enable --now opencode.service
