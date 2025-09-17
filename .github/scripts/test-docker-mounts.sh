#!/bin/bash
# Test Docker Mount Configurations Script
# Tests various mount strategies for Docker container execution

set -euo pipefail

echo "🧪 Testing Docker mount configurations..."

# Get environment variables
CURRENT_DIR=$(pwd)
LEVERAGE_GITCONFIG="${LEVERAGE_GITCONFIG:-$HOME/.gitconfig}"
LEVERAGE_SSH_DIR="${LEVERAGE_SSH_DIR:-$HOME/.ssh}"
LEVERAGE_AWS_DIR="${LEVERAGE_AWS_DIR:-$HOME/.aws}"

# Test basic container execution
echo "🧪 Testing basic container execution..."
if docker run --rm hello-world; then
    echo "✅ Basic Docker container execution successful"
else
    echo "❌ Basic Docker container execution failed"
fi

# Test bind mount with current directory (same pattern Leverage CLI will use)
echo "🔗 Testing bind mount with current working directory:"
echo "Current directory for mount test: $CURRENT_DIR"

if docker run --rm -v "$CURRENT_DIR:/workspace" -w /workspace alpine:latest pwd; then
    echo "✅ Basic bind mount test successful"
else
    echo "❌ Basic bind mount test failed"
fi

# Test bind mount with file listing (verify mount contents)
echo "🔗 Testing bind mount file access:"
if docker run --rm -v "$CURRENT_DIR:/workspace" -w /workspace alpine:latest ls -la; then
    echo "✅ Bind mount file listing successful"
else
    echo "❌ Bind mount file listing failed"
fi

# Test specific build.env file access in container
echo "🔗 Testing build.env access in container:"
if docker run --rm -v "$CURRENT_DIR:/workspace" -w /workspace alpine:latest cat build.env; then
    echo "✅ build.env accessible in container"
else
    echo "❌ build.env not accessible in container"
fi

# Test configuration file mounts using runner.temp (GitHub Actions compatible)
echo "🔗 Testing configuration file mounts with runner.temp paths (fixing GitHub Actions restrictions):"

# Test Git config mount using runner.temp
echo "Git config mount test (runner.temp):"
if docker run --rm -v "$LEVERAGE_GITCONFIG:/home/leverage/.gitconfig:ro,z" alpine:latest ls -la /home/leverage/.gitconfig; then
    echo "✅ Git config mount successful with runner.temp"
else
    echo "❌ Git config mount failed - checking if file exists:"
    ls -la "$LEVERAGE_GITCONFIG" || echo "Git config file does not exist in runner.temp"
fi

# Test SSH config mount using runner.temp
echo "SSH config mount test (runner.temp):"
if docker run --rm -v "$LEVERAGE_SSH_DIR:/home/leverage/.ssh:ro,z" alpine:latest ls -la /home/leverage/.ssh; then
    echo "✅ SSH config mount successful with runner.temp"
else
    echo "❌ SSH config mount failed - checking if directory exists:"
    ls -la "$LEVERAGE_SSH_DIR" || echo "SSH config directory does not exist in runner.temp"
fi

# Test AWS config mount using runner.temp
echo "AWS config mount test (runner.temp):"
if docker run --rm -v "$LEVERAGE_AWS_DIR:/home/leverage/.aws:ro,z" alpine:latest ls -la /home/leverage/.aws; then
    echo "✅ AWS config mount successful with runner.temp"
else
    echo "❌ AWS config mount failed - checking if directory exists:"
    ls -la "$LEVERAGE_AWS_DIR" || echo "AWS config directory does not exist in runner.temp"
fi

# Test fallback mounts using HOME symlinks (compatibility test)
echo "Testing fallback mounts using HOME symlinks:"
echo "Git config fallback test:"
if docker run --rm -v "$HOME/.gitconfig:/home/leverage/.gitconfig:ro,z" alpine:latest ls -la /home/leverage/.gitconfig 2>/dev/null; then
    echo "✅ Git config fallback mount successful"
else
    echo "⚠️ Git config fallback mount failed (expected if symlinks don't work in containers)"
fi

# Test final mount verification with validated sources
echo "🔗 Final mount verification test with validated sources:"
if docker run --rm \
    -v "$CURRENT_DIR:/workspace:z" \
    -v "$LEVERAGE_GITCONFIG:/home/leverage/.gitconfig:ro,z" \
    -v "$LEVERAGE_SSH_DIR:/home/leverage/.ssh:ro,z" \
    -v "$LEVERAGE_AWS_DIR:/home/leverage/.aws:ro,z" \
    -w /workspace \
    alpine:latest \
    sh -c "echo 'All validated mounts working:'; ls -la /workspace/build.env; ls -la /home/leverage/.gitconfig; ls -la /home/leverage/.ssh/; ls -la /home/leverage/.aws/"; then
    echo "✅ Final mount verification successful"
else
    echo "⚠️ Final mount verification failed, but proceeding with Leverage CLI test"
fi

echo "✅ Docker mount testing complete"