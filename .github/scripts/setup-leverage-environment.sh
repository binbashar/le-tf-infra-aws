#!/bin/bash
# Setup Leverage CLI Environment Script
# Comprehensive Docker bind mount fixes with enhanced fallback strategies

set -euo pipefail

echo "🔧 Setting up Leverage CLI environment with comprehensive Docker bind mount fixes..."

# Apply official Leverage CLI troubleshooting fixes
echo "🔧 Applying official troubleshooting environment variables..."

# OFFICIAL FIX: Unset SSH_AUTH_SOCK (from troubleshooting guide)
unset SSH_AUTH_SOCK || true
echo "SSH_AUTH_SOCK=" >> "$GITHUB_ENV"
echo "✅ SSH_AUTH_SOCK unset (official troubleshooting fix)"

# Set Docker environment variables (mirroring local setup + official guidance)
export DOCKER_HOST=unix:///var/run/docker.sock
echo "DOCKER_HOST=unix:///var/run/docker.sock" >> "$GITHUB_ENV"
echo "✅ DOCKER_HOST set to: $DOCKER_HOST"

# CREATE CONFIGURATION FILES IN RUNNER TEMP (Fix for GitHub Actions mount restrictions)
echo "🔧 Creating configuration files in runner.temp to fix GitHub Actions mount restrictions..."

# Use runner.temp for all configuration files (GitHub Actions approved mount location)
CONFIG_DIR="${RUNNER_TEMP}/leverage-config"
mkdir -p "$CONFIG_DIR"

# Create minimal .gitconfig file in runner.temp
GITCONFIG_FILE="$CONFIG_DIR/.gitconfig"
mkdir -p "$(dirname "$GITCONFIG_FILE")"
cat > "$GITCONFIG_FILE" << 'EOF'
[user]
	name = GitHub Actions
	email = actions@github.com
[init]
	defaultBranch = main
[safe]
	directory = *
EOF
echo "✅ Created .gitconfig at $GITCONFIG_FILE"

# Create SSH config directory and files in runner.temp
SSH_DIR="$CONFIG_DIR/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Create empty SSH config file
touch "$SSH_DIR/config"
chmod 600 "$SSH_DIR/config"

# Create empty known_hosts file
touch "$SSH_DIR/known_hosts"
chmod 600 "$SSH_DIR/known_hosts"

echo "✅ Created SSH configuration directory and files at $SSH_DIR"

# Create AWS config directory in runner.temp
AWS_DIR="$CONFIG_DIR/.aws"
mkdir -p "$AWS_DIR"
touch "$AWS_DIR/config"
touch "$AWS_DIR/credentials"
chmod 600 "$AWS_DIR/config" "$AWS_DIR/credentials"
echo "✅ Created AWS configuration directory and files at $AWS_DIR"

# Set environment variables for mount paths (GitHub Actions compatible)
echo "LEVERAGE_CONFIG_DIR=$CONFIG_DIR" >> "$GITHUB_ENV"
echo "LEVERAGE_GITCONFIG=$GITCONFIG_FILE" >> "$GITHUB_ENV"
echo "LEVERAGE_SSH_DIR=$SSH_DIR" >> "$GITHUB_ENV"
echo "LEVERAGE_AWS_DIR=$AWS_DIR" >> "$GITHUB_ENV"

# Also create symlinks in HOME for compatibility (fallback)
echo "🔗 Creating compatibility symlinks in HOME directory..."
mkdir -p "$HOME"
ln -sf "$GITCONFIG_FILE" "$HOME/.gitconfig" || echo "Could not create gitconfig symlink"
ln -sf "$SSH_DIR" "$HOME/.ssh" || echo "Could not create SSH symlink"
ln -sf "$AWS_DIR" "$HOME/.aws" || echo "Could not create AWS symlink"
echo "✅ Created compatibility symlinks"

# List created files for verification
echo "📁 Created configuration files:"
echo "Runner temp config dir: $(ls -la "$CONFIG_DIR" 2>/dev/null || echo 'NOT FOUND')"
echo "Git config (runner.temp): $(ls -la "$GITCONFIG_FILE" 2>/dev/null || echo 'NOT FOUND')"
echo "SSH directory (runner.temp): $(ls -la "$SSH_DIR" 2>/dev/null || echo 'NOT FOUND')"
echo "AWS directory (runner.temp): $(ls -la "$AWS_DIR" 2>/dev/null || echo 'NOT FOUND')"
echo "Git config (HOME symlink): $(ls -la "$HOME/.gitconfig" 2>/dev/null || echo 'NOT FOUND')"
echo "SSH directory (HOME symlink): $(ls -la "$HOME/.ssh" 2>/dev/null || echo 'NOT FOUND')"
echo "AWS directory (HOME symlink): $(ls -la "$HOME/.aws" 2>/dev/null || echo 'NOT FOUND')"

# Verify environment variables are set correctly
echo "🔍 Environment variable verification:"
echo "SSH_AUTH_SOCK: '$SSH_AUTH_SOCK' (should be empty)"
echo "DOCKER_HOST: '$DOCKER_HOST'"
echo "LEVERAGE_CONFIG_DIR: '$CONFIG_DIR'"
echo "LEVERAGE_GITCONFIG: '$GITCONFIG_FILE'"
echo "LEVERAGE_SSH_DIR: '$SSH_DIR'"
echo "LEVERAGE_AWS_DIR: '$AWS_DIR'"

echo "✅ Leverage CLI environment setup complete with comprehensive Docker bind mount fixes"