#!/bin/bash
# Detect Best Validation Strategy Script
# Determines the optimal validation approach based on environment capabilities

set -euo pipefail

echo "🔧 Attempting alternative validation approaches..."

# Get environment variables
CURRENT_DIR=$(pwd)
LEVERAGE_GITCONFIG="${LEVERAGE_GITCONFIG:-$HOME/.gitconfig}"
LEVERAGE_SSH_DIR="${LEVERAGE_SSH_DIR:-$HOME/.ssh}"
LEVERAGE_AWS_DIR="${LEVERAGE_AWS_DIR:-$HOME/.aws}"

# Try using basic Leverage CLI commands (v2.1.1 compatible)
echo "🧪 Testing basic Leverage CLI functionality..."

# Test basic leverage tf command without mount options
if timeout 60 leverage --verbose tf version 2>&1; then
    echo "✅ Basic Leverage CLI approach successful"
    echo "VALIDATION_STRATEGY=leverage_standard" >> "$GITHUB_ENV"
    exit 0
else
    echo "⚠️ Basic Leverage CLI approach failed"
fi

# Try minimal containerless approach (if available)
echo "🧪 Testing minimal validation without problematic mounts..."

# Check if we can run basic terraform commands directly
if command -v terraform >/dev/null 2>&1; then
    echo "✅ Found local terraform installation, attempting direct validation"
    echo "Terraform version: $(terraform version)"

    # Try basic terraform operations without Leverage CLI
    echo "Testing direct terraform fmt..."
    if terraform fmt -check -diff .; then
        echo "✅ Direct terraform format check successful"
        echo "VALIDATION_STRATEGY=direct_terraform" >> "$GITHUB_ENV"
        exit 0
    else
        echo "⚠️ Direct terraform format check failed (files need formatting)"
        echo "VALIDATION_STRATEGY=direct_terraform" >> "$GITHUB_ENV" # Still usable, just needs formatting
        exit 0
    fi
else
    echo "⚠️ No local terraform installation found"
fi

echo "🎯 Using default Leverage CLI strategy"
echo "VALIDATION_STRATEGY=default" >> "$GITHUB_ENV"