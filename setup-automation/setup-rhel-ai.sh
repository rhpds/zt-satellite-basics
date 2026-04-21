#!/bin/bash

echo "starting setup-rhel-ai.sh" >> /tmp/setup-scripts/setup-rhel-ai.log

# SSH to Satellite, create admin Hammer access token for MCP.
export FOREMAN_TOKEN=$(ssh satellite.lab 'hammer user access-token create --user=admin --name="mcp server token"' | tail -1)

# Upgrade opencode
/root/.opencode/bin/opencode upgrade

# Persist OpenCode LiteLLM configuration: write config.json with the Litellm provider configuration (heredoc unquoted so the variable is substituted).
mkdir -p /root/.config/opencode/
cat > /root/.config/opencode/config.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "litellm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LiteLLM",
      "options": {
        "baseURL": "$LITELLM_API_URL"
      },
      "models": {
        "minimax-m2": {
          "name": "minimax-m2"
        }
      }
    }
  },
  "mcp": {
    "satellite-mcp": {
      "type": "remote",
      "url": "http://localhost:8080/mcp",
      "enabled": true,
      "headers": {
        "FOREMAN_USERNAME": "admin",
        "FOREMAN_TOKEN": "$FOREMAN_TOKEN"
      }
    },
    "rhel-mcp": {
      "type": "local",
      "enabled": true,
      "command": ["/usr/local/bin/linux-mcp-server","--no-verify-host-keys"]
    }
  }
}
EOF

# Persist OpenCode LiteLLM API credentials: write auth.json with the LITELLM_API_KEY from the environment (heredoc unquoted so the variable is substituted).
mkdir -p /root/.local/share/opencode/
cat > /root/.local/share/opencode/auth.json << EOF
{
  "litellm": {
    "type": "api",
    "key": "$LITELLM_API_KEY"
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

# Install and start OpenCode web interface systemd unit.
cat > /etc/systemd/system/opencode.service << 'EOF'
[Unit]
Description=OpenCode Web Interface
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/root/.opencode/bin/opencode web --port 9999 --hostname 0.0.0.0
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
