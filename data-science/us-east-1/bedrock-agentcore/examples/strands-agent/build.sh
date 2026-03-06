#!/usr/bin/env bash
#
# Build deployment package for a Strands agent on AgentCore.
#
# Mirrors the build process of `agentcore deploy` (direct_code_deploy):
#   1. Resolve deps from pyproject.toml → requirements.txt
#   2. Cross-compile for ARM64 (AgentCore runs on Graviton)
#   3. Bundle deps + source into a flat zip
#
# Output: ../../.build/agent.zip (where the Leverage layer expects it)
#
# Prerequisites: uv (https://docs.astral.sh/uv/getting-started/installation/)
#
set -euo pipefail

PYTHON_VERSION="3.12"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYER_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${LAYER_DIR}/.build/package"
OUTPUT="${LAYER_DIR}/.build/agent.zip"

echo "==> Building AgentCore deployment package (Python ${PYTHON_VERSION}, linux/arm64)..."

# Ensure uv is available
if ! command -v uv &>/dev/null; then
  echo "==> Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

rm -rf "$BUILD_DIR" "$OUTPUT"
mkdir -p "$BUILD_DIR"

# Resolve dependencies (pyproject.toml → requirements.txt)
uv pip compile --quiet \
  "${SCRIPT_DIR}/pyproject.toml" \
  --output-file "${LAYER_DIR}/.build/requirements.txt" \
  --python-version "$PYTHON_VERSION" \
  --python-platform aarch64-manylinux2014

# Install dependencies cross-compiled for ARM64 (Graviton)
uv pip install --quiet \
  --target "$BUILD_DIR" \
  --python-version "$PYTHON_VERSION" \
  --python-platform aarch64-manylinux2014 \
  --only-binary :all: \
  -r "${LAYER_DIR}/.build/requirements.txt"

# Overlay agent source code (takes precedence over deps on conflicts)
cp "${SCRIPT_DIR}"/*.py "$BUILD_DIR/"

# Create deployment zip
cd "$BUILD_DIR"
python3 -c "import shutil; shutil.make_archive('../agent', 'zip', '.')"

echo "==> Deployment package created: ${OUTPUT} ($(du -h "$OUTPUT" | cut -f1))"
