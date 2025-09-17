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

# Try using Leverage CLI with explicit mount and environment variable control
echo "🧪 Testing Leverage CLI with explicit mount control..."

# Use explicit mount syntax to bypass automatic mount detection
if timeout 60 leverage \
    --mount "$CURRENT_DIR" "/workspace" \
    --mount "$LEVERAGE_GITCONFIG" "/home/leverage/.gitconfig" \
    --mount "$LEVERAGE_SSH_DIR" "/home/leverage/.ssh" \
    --mount "$LEVERAGE_AWS_DIR" "/home/leverage/.aws" \
    --env-var "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID" \
    --env-var "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY" \
    --env-var "AWS_DEFAULT_REGION" "$AWS_DEFAULT_REGION" \
    --verbose tf version 2>&1; then
    echo "✅ Explicit mount control approach successful"
    echo "VALIDATION_STRATEGY=explicit_mounts" >> "$GITHUB_ENV"
    exit 0
fi

echo "⚠️ Explicit mount control approach failed"

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

# Try with simplified mount pattern (only essential mounts)
echo "🧪 Testing simplified mount pattern..."
if timeout 60 leverage \
    --mount "$CURRENT_DIR" "/workspace" \
    --env-var "AWS_DEFAULT_REGION" "$AWS_DEFAULT_REGION" \
    --verbose tf version 2>&1; then
    echo "✅ Simplified mount pattern successful"
    echo "VALIDATION_STRATEGY=simplified_mounts" >> "$GITHUB_ENV"
    exit 0
else
    echo "⚠️ Simplified mount pattern failed"
fi

echo "🎯 Using default strategy (may have mount issues)"
echo "VALIDATION_STRATEGY=default" >> "$GITHUB_ENV"