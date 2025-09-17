#!/bin/bash
# Setup Leverage CLI Environment Script
# Essential SSH agent socket fix for Docker bind mount compatibility

set -euo pipefail

echo "🔧 Setting up Leverage CLI environment..."

# Set Docker environment variables
export DOCKER_HOST=unix:///var/run/docker.sock
echo "DOCKER_HOST=unix:///var/run/docker.sock" >> "$GITHUB_ENV"

# Create configuration directory
CONFIG_DIR="${RUNNER_TEMP}/leverage-config"
mkdir -p "$CONFIG_DIR"

# Create dummy SSH agent socket to prevent Docker bind mount errors
SSH_AGENT_SOCK="$CONFIG_DIR/ssh-agent.sock"
touch "$SSH_AGENT_SOCK"
export SSH_AUTH_SOCK="$SSH_AGENT_SOCK"
echo "SSH_AUTH_SOCK=$SSH_AGENT_SOCK" >> "$GITHUB_ENV"
echo "✅ Created SSH agent socket: $SSH_AGENT_SOCK"

# Create basic configuration files
mkdir -p "$HOME/.ssh" "$HOME/.aws"
touch "$HOME/.ssh/config" "$HOME/.ssh/known_hosts"
touch "$HOME/.aws/config" "$HOME/.aws/credentials"
chmod 700 "$HOME/.ssh" "$HOME/.aws"
chmod 600 "$HOME/.ssh/config" "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.aws/config" "$HOME/.aws/credentials"

# Create minimal .gitconfig
cat > "$HOME/.gitconfig" << 'EOF'
[user]
	name = GitHub Actions
	email = actions@github.com
[init]
	defaultBranch = main
[safe]
	directory = *
EOF
chmod 600 "$HOME/.gitconfig"

echo "✅ Leverage CLI environment setup complete"