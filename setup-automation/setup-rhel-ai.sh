#!/bin/bash

echo "starting setup-rhel-ai.sh" >> /tmp/setup-scripts/setup-rhel-ai.log

# SSH to Satellite, create admin Hammer access token for MCP.
export FOREMAN_TOKEN=$(ssh satellite.lab 'hammer user access-token create --user=admin --name="mcp server token"' | tail -1)

# Persist OpenCode LiteLLM configuration: write config.json with the Litellm provider configuration (heredoc unquoted so the variable is substituted).
mkdir -p /root/.config/opencode/
cat > /root/.config/opencode/config.json << EOF
{
  "$schema": "https://opencode.ai/config.json",
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
