#!/bin/bash
# Container Health Check Script
# Comprehensive Docker container health validation and debugging

set -euo pipefail

echo "🏥 Container Health Check Starting..."

# Function to safely execute commands with error handling
safe_execute() {
    local cmd="$1"
    local description="$2"

    echo "🔍 Testing: $description"
    echo "Command: $cmd"

    if output=$(timeout 60 $cmd 2>&1); then
        echo "✅ SUCCESS: $description"
        echo "Output: $output"
        return 0
    else
        local exit_code=$?
        echo "❌ FAILED: $description (exit code: $exit_code)"
        echo "Error output: $output"
        return $exit_code
    fi
}

# Test 1: Basic Docker functionality
echo "=== Phase 1: Docker Engine Health ==="
safe_execute "docker --version" "Docker version check"
safe_execute "docker info" "Docker engine info"
safe_execute "docker ps -a" "List all containers"

# Test 2: Container creation test
echo "=== Phase 2: Container Creation Test ==="
safe_execute "docker run --rm hello-world" "Basic container execution"

# Test 3: Leverage CLI basic functionality
echo "=== Phase 3: Leverage CLI Basic Tests ==="
safe_execute "leverage --version" "Leverage CLI version"
safe_execute "leverage --help" "Leverage CLI help"

# Test 4: Environment validation
echo "=== Phase 4: Environment Validation ==="
echo "Current directory: $(pwd)"
echo "Python version: $(python3 --version 2>&1 || echo 'Python not available')"
echo "Virtual environment: ${VIRTUAL_ENV:-not set}"
echo "PATH: $PATH"

# Test 5: AWS credentials check (safe - no secret exposure)
echo "=== Phase 5: AWS Credentials Validation ==="
echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:+configured (length: ${#AWS_ACCESS_KEY_ID})}"
echo "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:+configured (length: ${#AWS_SECRET_ACCESS_KEY})}"
echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION:-not set}"

# Test 6: Configuration files check
echo "=== Phase 6: Configuration Files Check ==="
echo "Build config files:"
find . -name "build.env" -type f 2>/dev/null | head -5 | while read -r file; do
    echo "Found: $file"
    echo "Content preview: $(head -3 "$file" 2>/dev/null || echo 'Cannot read file')"
done

# Test 7: Docker Leverage toolbox image test
echo "=== Phase 7: Leverage Toolbox Image Test ==="
IMAGE_TAG="${TERRAFORM_IMAGE_TAG:-1.9.1-tofu-0.3.0}"
LEVERAGE_IMAGE="binbash/leverage-toolbox:${IMAGE_TAG}"

echo "Testing Leverage toolbox image: $LEVERAGE_IMAGE"
safe_execute "docker pull $LEVERAGE_IMAGE" "Pull Leverage toolbox image"
safe_execute "docker run --rm $LEVERAGE_IMAGE tofu --version" "Test OpenTofu in container"

echo "🏥 Container Health Check Complete"