#!/bin/bash
# AWS Credentials and Configuration Validation Script
# Tests AWS connectivity and credential configuration in GitHub Actions

set -euo pipefail

echo "🔑 AWS Validation Starting..."

# Function to safely test AWS commands
test_aws_command() {
    local cmd="$1"
    local description="$2"

    echo "🔍 Testing: $description"
    echo "Command: $cmd"

    if output=$(timeout 30 $cmd 2>&1); then
        echo "✅ SUCCESS: $description"
        echo "Output: $output"
        return 0
    else
        local exit_code=$?
        echo "❌ FAILED: $description (exit code: $exit_code)"
        echo "Error output: $output"
        return 1
    fi
}

# Phase 1: Environment validation
echo "=== Phase 1: AWS Environment Validation ==="
echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:+configured (length: ${#AWS_ACCESS_KEY_ID})}"
echo "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:+configured (length: ${#AWS_SECRET_ACCESS_KEY})}"
echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION:-not set}"
echo "AWS_REGION: ${AWS_REGION:-not set}"

# Phase 2: AWS CLI availability (if installed)
echo "=== Phase 2: AWS CLI Availability ==="
if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI found: $(aws --version 2>&1 || echo 'version check failed')"

    # Test basic AWS CLI functionality
    test_aws_command "aws sts get-caller-identity --no-cli-pager" "AWS STS Get Caller Identity"
    test_aws_command "aws sts get-session-token --no-cli-pager --duration-seconds 900" "AWS STS Get Session Token"
else
    echo "AWS CLI not available (this is expected in Leverage CLI workflows)"
fi

# Phase 3: Test AWS connectivity through container
echo "=== Phase 3: Container AWS Connectivity Test ==="
IMAGE_TAG="${TERRAFORM_IMAGE_TAG:-1.9.1-tofu-0.3.0}"
LEVERAGE_IMAGE="binbash/leverage-toolbox:${IMAGE_TAG}"

echo "Testing AWS connectivity through Leverage toolbox: $LEVERAGE_IMAGE"

# Test AWS credentials in container environment
if docker images | grep -q "binbash/leverage-toolbox"; then
    echo "Testing AWS credentials in container..."

    # Note: The leverage toolbox contains OpenTofu but may not have AWS CLI
    # Test if AWS CLI is available in the container first
    if docker run --rm $LEVERAGE_IMAGE which aws >/dev/null 2>&1; then
        echo "AWS CLI found in container, testing credentials..."
        test_aws_command "docker run --rm -e AWS_ACCESS_KEY_ID=\"\$AWS_ACCESS_KEY_ID\" -e AWS_SECRET_ACCESS_KEY=\"\$AWS_SECRET_ACCESS_KEY\" -e AWS_DEFAULT_REGION=\"\$AWS_DEFAULT_REGION\" $LEVERAGE_IMAGE aws sts get-caller-identity --no-cli-pager" "Container AWS STS Test"
    else
        echo "⚠️ AWS CLI not available in leverage toolbox container (this is expected)"
        echo "✅ Skipping container AWS credential test - will rely on Leverage CLI for AWS access"
    fi
else
    echo "Leverage toolbox image not available for testing"
fi

# Phase 4: Test Leverage CLI AWS integration
echo "=== Phase 4: Leverage CLI AWS Integration ==="
if command -v leverage >/dev/null 2>&1; then
    echo "Testing Leverage CLI AWS integration..."

    # Test if Leverage CLI can access AWS credentials
    test_aws_command "leverage aws --help" "Leverage AWS help command"

    # Note: We don't run 'leverage aws sso login' as it's interactive
    echo "Note: Skipping interactive AWS SSO commands in automated environment"
else
    echo "Leverage CLI not found"
fi

echo "🔑 AWS Validation Complete"