# Bedrock AgentCore

Deploys an [Amazon Bedrock AgentCore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html) Runtime and Endpoint for hosting AI agents on AWS — serverless, session-isolated, and fully managed.

## Architecture

```
                        ┌─────────────────────────────────────────────────────┐
                        │              AWS Account (data-science)             │
                        │                                                     │
  leverage tf apply     │  ┌───────────┐    ┌──────────────────────────────┐  │
 ─────────────────────► │  │  S3       │    │  Bedrock AgentCore           │  │
  (uploads agent.zip)   │  │  Bucket   │    │                              │  │
                        │  │           │◄───│  ┌────────────────────────┐  │  │
                        │  │ agent.zip │    │  │  Runtime               │  │  │
                        │  └───────────┘    │  │  (loads code from S3)  │  │  │
                        │                   │  │                        │  │  │
                        │                   │  │  Python 3.12 / ARM64   │  │  │
                        │                   │  │  Strands + Bedrock     │  │  │
                        │                   │  └──────────┬─────────────┘  │  │
                        │                   │             │                │  │
                        │                   │  ┌──────────▼─────────────┐  │  │
  invoke (HTTP/WS)      │                   │  │  Endpoint              │  │  │
 ─────────────────────► │                   │  │  (addressable URL)     │  │  │
  (base64 JSON payload) │                   │  │                        │  │  │
                        │                   │  │  Each session runs in  │  │  │
                        │                   │  │  an isolated microVM   │  │  │
                        │                   │  └────────────────────────┘  │  │
                        │                   └──────────────────────────────┘  │
                        │                                                     │
                        │  ┌───────────┐    ┌───────────┐   ┌──────────────┐  │
                        │  │ IAM Role  │    │ CloudWatch│   │ Bedrock LLM  │  │
                        │  │ (runtime) │    │ Logs      │   │ (Nova Lite)  │  │
                        │  └───────────┘    └───────────┘   └──────────────┘  │
                        └─────────────────────────────────────────────────────┘
```

**How AgentCore Runtime works:** Your agent code (a zip with dependencies) is uploaded to S3. The Runtime loads it and exposes it through an Endpoint. When invoked, each user session spins up in a dedicated microVM with isolated CPU, memory, and filesystem. Sessions persist up to 8 hours and are fully terminated (memory sanitized) on idle timeout. See [How it works](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-how-it-works.html).

## Prerequisites

- AWS SSO authenticated: `leverage aws sso login`
- Agent zip built at `artifact_path` (default: `.build/agent.zip`)
- [uv](https://docs.astral.sh/uv/) for building the example agent

## Quick Start

```bash
cd data-science/us-east-1/bedrock-agentcore

# 1. Build the example agent (or bring your own zip)
cd examples/strands-agent && bash build.sh && cd ../..

# 2. Deploy
leverage tf init
leverage tf plan
leverage tf apply

# 3. Smoke test
AWS_PROFILE=<your-sso-profile> ./examples/strands-agent/test.sh
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `artifact_path` | `.build/agent.zip` | Path to agent zip (relative to layer) |
| `runtime_name` | `PYTHON_3_12` | Python version (`PYTHON_3_10` / `3_11` / `3_12` / `3_13`) |
| `entry_point` | `["agent.py"]` | Entrypoint file(s) for the runtime |
| `environment_variables` | `{}` | Env vars passed to the runtime |
| `runtime_description` | `"...deployed via Leverage"` | Runtime description |
| `endpoint_description` | `"...deployed via Leverage"` | Endpoint description |

## Outputs

| Output | Description |
|--------|-------------|
| `agent_runtime_id` | Runtime ID (used for control plane operations) |
| `agent_runtime_arn` | Runtime ARN (used for invocation) |
| `agent_runtime_endpoint_id` | Endpoint name/ID |
| `agent_runtime_endpoint_arn` | Endpoint ARN |
| `runtime_role_arn` | IAM role ARN |
| `code_bucket_name` | S3 bucket for agent artifacts |

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Direct AWSCC resources** | The `aws-ia/agentcore/aws` module (v0.0.4) requires AWS provider v6+ and has OpenTofu-incompatible validation blocks |
| **Code configuration** (not container) | Eliminates Docker build, ECR push, multi-step apply. Single `leverage tf apply` deploys everything |
| **Pure infrastructure** | Layer does not build agent code — artifacts are produced externally and passed in |
| **Pre-bundled dependencies** | AgentCore does not auto-install from `pyproject.toml`; the zip must include all deps |
| **PUBLIC network mode** | No VPC dependency for first iteration |
| **IAM auth** (default) | No Cognito/JWT authorizer — keeps the layer minimal |
| **Python 3.12** | Matches `agentcore configure` defaults; broad library compatibility |
| **AWSCC naming** (`_` not `-`) | AWSCC requires `^[a-zA-Z][a-zA-Z0-9_]{0,47}$` |
| **15s IAM wait** | `time_sleep` after role creation for AWS eventual consistency propagation |

## Layer Structure

```
bedrock-agentcore/
├── config.tf          # Backend + providers (aws, awscc, time)
├── locals.tf          # Naming, tags, sanitized AWSCC names
├── variables.tf       # Layer inputs
├── outputs.tf         # Runtime/endpoint IDs and ARNs
├── main.tf            # AgentCore Runtime + Endpoint (AWSCC)
├── iam.tf             # IAM role, policies, propagation wait
├── code.tf            # S3 bucket + artifact upload
└── examples/
    └── strands-agent/
        ├── agent.py       # Minimal Strands agent (Nova Lite)
        ├── pyproject.toml # Agent dependencies
        ├── build.sh       # Cross-compile for ARM64/Graviton → .build/agent.zip
        └── test.sh        # Smoke test (runtime status, endpoint, invocation)
```

## Testing

The smoke test validates the deployed infrastructure end-to-end:

```bash
# Auto-detect runtime IDs from terraform state
AWS_PROFILE=<your-sso-profile> ./examples/strands-agent/test.sh

# Or pass IDs explicitly (faster, skips leverage tf output)
RUNTIME_ID=xxx ENDPOINT_NAME=yyy AWS_PROFILE=<profile> ./examples/strands-agent/test.sh
```

**What it checks:** runtime status `READY`, endpoint status `READY`, agent invocation returns HTTP 200, response payload contains `"status": "success"` with non-empty text.

**Requirements:** `aws` CLI v2, `jq`, authenticated AWS profile with data-science account access.

## AWS CLI Reference

AgentCore uses two separate CLI services:

```bash
# Control plane (CRUD) — bedrock-agentcore-control
aws bedrock-agentcore-control get-agent-runtime --agent-runtime-id <ID>
aws bedrock-agentcore-control get-agent-runtime-endpoint \
  --agent-runtime-id <ID> --endpoint-name <NAME>

# Data plane (invoke) — bedrock-agentcore
aws bedrock-agentcore invoke-agent-runtime \
  --agent-runtime-arn <ARN> --qualifier <ENDPOINT_NAME> \
  --payload "$(echo -n '{"prompt":"Hello"}' | base64)" \
  --content-type "application/json" output.json
```

> **Note:** The `bb-data-science-devops` profile from `backend.tfvars` only exists inside the leverage Docker container. Use your own SSO profile (e.g., `binbash`) for direct AWS CLI calls.

## Roadmap

This layer is a minimal first iteration. Planned improvements:

| Feature | What it enables |
|---------|-----------------|
| **Container deployment** | Support `container_configuration` alongside code — allows custom Docker images, larger runtimes, and system-level deps via ECR |
| **OAuth / OIDC auth** | Replace IAM-only auth with [AgentCore Identity](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity.html) inbound auth — integrate Cognito, Okta, or Entra ID so end-users authenticate with bearer tokens |
| **AgentCore Memory** | Add [Memory](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory.html) for short-term (multi-turn conversation) and long-term (cross-session) context persistence |
| **AgentCore Gateway** | Expose APIs, Lambda functions, and MCP servers as agent tools via [Gateway](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway.html) endpoints |
| **Observability** | Enable [AgentCore Observability](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/observability.html) for tracing agent reasoning steps, tool invocations, and model interactions (OpenTelemetry-compatible) |
| **VPC network mode** | Replace PUBLIC with VPC mode for private subnet deployment and security group controls |
| **WebSocket streaming** | Enable bidirectional streaming for real-time interactive agent responses |
| **Multi-agent (A2A/MCP)** | Deploy agents that communicate with other agents via [Agent-to-Agent](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-a2a.html) or [MCP](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html) protocols |
