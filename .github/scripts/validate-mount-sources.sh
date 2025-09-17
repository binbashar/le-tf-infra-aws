#!/bin/bash
# Validate and Fix Mount Sources Script
# Comprehensive mount source validation and permission fixing

set -euo pipefail

echo "🔧 Comprehensive mount source validation and permission fixing..."

# Function to validate and fix mount source
validate_mount_source() {
    local source_path="$1"
    local source_type="$2"
    local description="$3"

    echo "Validating $description: $source_path"

    if [[ ! -e "$source_path" ]]; then
        echo "❌ $description does not exist, creating..."
        if [[ "$source_type" == "file" ]]; then
            mkdir -p "$(dirname "$source_path")"
            touch "$source_path"
        else
            mkdir -p "$source_path"
        fi
    fi

    # Check if source exists after creation
    if [[ -e "$source_path" ]]; then
        echo "✅ $description exists: $(ls -la "$source_path")"

        # Fix permissions based on type
        if [[ "$source_type" == "file" ]]; then
            chmod 644 "$source_path"
        else
            chmod 755 "$source_path"
            # For directories, also fix contents
            find "$source_path" -type f -exec chmod 644 {} \; 2>/dev/null || true
            find "$source_path" -type d -exec chmod 755 {} \; 2>/dev/null || true
        fi

        echo "✅ $description permissions fixed"
        return 0
    else
        echo "❌ Failed to create $description"
        return 1
    fi
}

# Get environment variables
CURRENT_DIR=$(pwd)
LEVERAGE_GITCONFIG="${LEVERAGE_GITCONFIG:-$HOME/.gitconfig}"
LEVERAGE_SSH_DIR="${LEVERAGE_SSH_DIR:-$HOME/.ssh}"
LEVERAGE_AWS_DIR="${LEVERAGE_AWS_DIR:-$HOME/.aws}"

# Debug output for environment variables
echo "🔍 Environment variables for mount sources:"
echo "LEVERAGE_GITCONFIG: ${LEVERAGE_GITCONFIG}"
echo "LEVERAGE_SSH_DIR: ${LEVERAGE_SSH_DIR}"
echo "LEVERAGE_AWS_DIR: ${LEVERAGE_AWS_DIR}"
echo "CURRENT_DIR: ${CURRENT_DIR}"

# Validate all mount sources
MOUNT_VALIDATION_FAILED=false

echo "📋 Validating all mount sources..."

# Validate current working directory
validate_mount_source "$CURRENT_DIR" "directory" "Current working directory" || MOUNT_VALIDATION_FAILED=true

# Validate runner.temp configuration files
validate_mount_source "$LEVERAGE_GITCONFIG" "file" "Git configuration file (runner.temp)" || MOUNT_VALIDATION_FAILED=true
validate_mount_source "$LEVERAGE_SSH_DIR" "directory" "SSH configuration directory (runner.temp)" || MOUNT_VALIDATION_FAILED=true
validate_mount_source "$LEVERAGE_AWS_DIR" "directory" "AWS configuration directory (runner.temp)" || MOUNT_VALIDATION_FAILED=true

# Ensure SSH directory has required files
validate_mount_source "$LEVERAGE_SSH_DIR/config" "file" "SSH config file" || MOUNT_VALIDATION_FAILED=true
validate_mount_source "$LEVERAGE_SSH_DIR/known_hosts" "file" "SSH known_hosts file" || MOUNT_VALIDATION_FAILED=true

# Ensure AWS directory has required files
validate_mount_source "$LEVERAGE_AWS_DIR/config" "file" "AWS config file" || MOUNT_VALIDATION_FAILED=true
validate_mount_source "$LEVERAGE_AWS_DIR/credentials" "file" "AWS credentials file" || MOUNT_VALIDATION_FAILED=true

# Validate build.env and config files
validate_mount_source "./build.env" "file" "build.env file" || MOUNT_VALIDATION_FAILED=true

# Check for backend and account config files
BACKEND_CONFIG="../../config/backend.tfvars"
ACCOUNT_CONFIG="../../config/account.tfvars"
if [[ -f "$BACKEND_CONFIG" ]]; then
    validate_mount_source "$BACKEND_CONFIG" "file" "Backend configuration file" || MOUNT_VALIDATION_FAILED=true
else
    echo "⚠️ Backend config file not found: $BACKEND_CONFIG (this may be expected)"
fi

if [[ -f "$ACCOUNT_CONFIG" ]]; then
    validate_mount_source "$ACCOUNT_CONFIG" "file" "Account configuration file" || MOUNT_VALIDATION_FAILED=true
else
    echo "⚠️ Account config file not found: $ACCOUNT_CONFIG (this may be expected)"
fi

# Final validation summary
if [[ "$MOUNT_VALIDATION_FAILED" == "true" ]]; then
    echo "⚠️ Some mount source validations failed, but continuing with available sources"
else
    echo "✅ All mount sources validated and prepared successfully"
fi

echo "✅ Mount source validation and permission fixing complete"