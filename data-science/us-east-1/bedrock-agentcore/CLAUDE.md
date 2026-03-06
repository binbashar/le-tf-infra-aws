# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layer Overview

Deploys a Bedrock AgentCore Runtime and Endpoint using direct AWSCC resources (`awscc_bedrockagentcore_runtime`, `awscc_bedrockagentcore_runtime_endpoint`). Code artifact is uploaded to S3 as a zip. Pure infrastructure — the layer does not build agent code; artifacts are produced externally.

## Commands

```bash
cd data-science/us-east-1/bedrock-agentcore

# Build the example agent artifact (required before apply)
cd examples/strands-agent && bash build.sh && cd ../..

# Deploy
leverage tf init
leverage tf plan
leverage tf apply

# Smoke test (from examples/strands-agent/)
RUNTIME_ID=<id> ENDPOINT_NAME=<name> AWS_PROFILE=<profile> ./test.sh

# Or auto-detect IDs from terraform state (slower, uses Docker)
AWS_PROFILE=<profile> ./test.sh
```

## Architecture

- **Direct AWSCC resources** instead of `aws-ia/agentcore/aws` module — that module (v0.0.4) requires AWS provider v6+ and has OpenTofu-incompatible validation blocks.
- **Code configuration** (not container) — eliminates Docker build, ECR push, multi-step apply. Single `leverage tf apply` deploys everything.
- **Pre-bundled dependencies** — AgentCore does not auto-install from pyproject.toml. The zip must include all deps (`examples/strands-agent/build.sh` cross-compiles for ARM64/Graviton).
- **AWSCC naming constraint**: `^[a-zA-Z][a-zA-Z0-9_]{0,47}$` — resource names use underscores (e.g., `bb_data_science_agentcore_runtime`), converted from the standard hyphenated prefix via `replace("-", "_")` in locals.
- **IAM auth** (default), **PUBLIC network mode**, **Python 3.12** — minimal first iteration.
- **15s `time_sleep`** after IAM role creation for eventual consistency propagation before runtime creation.

## AgentCore CLI Gotchas

- Two separate AWS CLI services: `bedrock-agentcore` (data plane: invoke) and `bedrock-agentcore-control` (control plane: CRUD)
- Invoke payload must be base64-encoded: `echo -n '{"prompt":"..."}' | base64`
- Endpoint parameter differs: `--endpoint-name` (control plane) vs `--qualifier` (data plane invoke)
- `bb-data-science-devops` profile only exists inside the leverage Docker container; use your SSO profile (e.g., `binbash`) for direct AWS CLI calls

## Troubleshooting

- `leverage tf output -json` mixes INFO lines into stdout — extract JSON with `sed -n '/{/,/^}/p'`
- Bash `((var++))` returns exit code 1 when var=0, killing scripts under `set -e` — use `var=$((var + 1))`
