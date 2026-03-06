#!/usr/bin/env bash
#
# Smoke test for the Bedrock AgentCore layer.
#
# Validates: runtime status, endpoint status, agent invocation, response payload.
#
# Prerequisites:
#   - AWS CLI v2 (with bedrock-agentcore service support)
#   - jq
#   - Authenticated AWS profile with access to the data-science account
#
# Usage:
#   AWS_PROFILE=<your-profile> ./test.sh
#
# Override auto-detected values (skips leverage tf output):
#   RUNTIME_ID=xxx ENDPOINT_NAME=yyy AWS_PROFILE=<profile> ./test.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

passed=0
failed=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; passed=$((passed + 1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; failed=$((failed + 1)); }
info() { echo -e "  ${YELLOW}....${NC} $1"; }

# --- Preflight: check dependencies ---
for cmd in aws jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Error:${NC} '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

if [[ -z "${AWS_PROFILE:-}" ]]; then
  echo -e "${RED}Error:${NC} AWS_PROFILE must be set. Example: AWS_PROFILE=binbash ./test.sh" >&2
  exit 1
fi

# --- Resolve runtime IDs ---
if [[ -n "${RUNTIME_ID:-}" && -n "${ENDPOINT_NAME:-}" ]]; then
  info "Using env vars: RUNTIME_ID=${RUNTIME_ID}, ENDPOINT_NAME=${ENDPOINT_NAME}"
else
  info "Reading outputs from terraform state (via leverage tf output)..."
  cd "$LAYER_DIR"

  # leverage tf output -json mixes INFO lines into stdout; extract the JSON block
  raw_output=$(leverage tf output -json 2>&1) || {
    echo -e "${RED}Error:${NC} 'leverage tf output -json' failed. Set RUNTIME_ID and ENDPOINT_NAME env vars instead." >&2
    exit 1
  }
  json_output=$(echo "$raw_output" | sed -n '/{/,/^}/p')

  RUNTIME_ID="${RUNTIME_ID:-$(echo "$json_output" | jq -r '.agent_runtime_id.value')}"
  ENDPOINT_NAME="${ENDPOINT_NAME:-$(echo "$json_output" | jq -r '.agent_runtime_endpoint_id.value')}"

  if [[ -z "$RUNTIME_ID" || "$RUNTIME_ID" == "null" || -z "$ENDPOINT_NAME" || "$ENDPOINT_NAME" == "null" ]]; then
    echo -e "${RED}Error:${NC} Could not read outputs from terraform state." >&2
    echo "Set RUNTIME_ID and ENDPOINT_NAME env vars manually." >&2
    exit 1
  fi
  info "Detected RUNTIME_ID=${RUNTIME_ID}"
  info "Detected ENDPOINT_NAME=${ENDPOINT_NAME}"
fi

RUNTIME_ARN="arn:aws:bedrock-agentcore:${REGION}:$(aws sts get-caller-identity --query Account --output text):runtime/${RUNTIME_ID}"

echo ""
echo -e "${BOLD}AgentCore Smoke Test${NC}"
echo -e "${BOLD}====================${NC}"
echo ""

# --- Test 1: Runtime status ---
info "Checking runtime status..."
runtime_json=$(aws bedrock-agentcore-control get-agent-runtime \
  --agent-runtime-id "$RUNTIME_ID" \
  --region "$REGION" 2>&1) || {
  fail "get-agent-runtime call failed: ${runtime_json}"
  runtime_status="ERROR"
}

if [[ -z "${runtime_status:-}" ]]; then
  runtime_status=$(echo "$runtime_json" | jq -r '.status')
fi

if [[ "$runtime_status" == "READY" ]]; then
  pass "Runtime status is READY"
else
  fail "Runtime status is '${runtime_status}' (expected READY)"
fi

# --- Test 2: Endpoint status ---
info "Checking endpoint status..."
endpoint_json=$(aws bedrock-agentcore-control get-agent-runtime-endpoint \
  --agent-runtime-id "$RUNTIME_ID" \
  --endpoint-name "$ENDPOINT_NAME" \
  --region "$REGION" 2>&1) || {
  fail "get-agent-runtime-endpoint call failed: ${endpoint_json}"
  endpoint_status="ERROR"
}

if [[ -z "${endpoint_status:-}" ]]; then
  endpoint_status=$(echo "$endpoint_json" | jq -r '.status')
fi

if [[ "$endpoint_status" == "READY" ]]; then
  pass "Endpoint status is READY"
else
  fail "Endpoint status is '${endpoint_status}' (expected READY)"
fi

# --- Test 3: Invoke agent ---
info "Invoking agent with test prompt..."
test_payload='{"prompt": "What is 2+2? Reply in one word."}'
encoded_payload=$(echo -n "$test_payload" | base64)
response_file=$(mktemp)
trap "rm -f '$response_file'" EXIT

invoke_meta=$(aws bedrock-agentcore invoke-agent-runtime \
  --agent-runtime-arn "$RUNTIME_ARN" \
  --qualifier "$ENDPOINT_NAME" \
  --content-type "application/json" \
  --accept "application/json" \
  --payload "$encoded_payload" \
  --region "$REGION" \
  "$response_file" 2>&1) || {
  fail "invoke-agent-runtime call failed: ${invoke_meta}"
  invoke_status="ERROR"
}

if [[ -z "${invoke_status:-}" ]]; then
  status_code=$(echo "$invoke_meta" | jq -r '.statusCode // empty')
  if [[ "$status_code" == "200" ]]; then
    pass "Invocation returned HTTP 200"
  else
    fail "Invocation returned HTTP ${status_code} (expected 200)"
  fi
fi

# --- Test 4: Validate response payload ---
if [[ -f "$response_file" && -s "$response_file" ]]; then
  response_status=$(jq -r '.status // empty' "$response_file" 2>/dev/null)
  response_text=$(jq -r '.response // empty' "$response_file" 2>/dev/null)

  if [[ "$response_status" == "success" ]]; then
    pass "Response status is 'success'"
  else
    fail "Response status is '${response_status}' (expected 'success')"
  fi

  if [[ -n "$response_text" && "$response_text" != "null" ]]; then
    pass "Response contains text: $(echo "$response_text" | head -c 80)"
  else
    fail "Response text is empty"
  fi
else
  fail "No response body received"
fi

# --- Summary ---
echo ""
total=$((passed + failed))
echo -e "${BOLD}Results: ${passed}/${total} passed${NC}"

if [[ "$failed" -gt 0 ]]; then
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed.${NC}"
  exit 0
fi
