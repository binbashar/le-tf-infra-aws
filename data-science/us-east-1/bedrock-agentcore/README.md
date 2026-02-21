# Bedrock AgentCore Layer

Deploys an [Amazon Bedrock AgentCore](https://docs.aws.amazon.com/bedrock/latest/userguide/agentcore.html) Runtime and Endpoint using direct AWSCC resources.

## Prerequisites

- AWS SSO authenticated: `leverage aws sso login`
- Layer initialized: `leverage tf init`
- Agent deployment zip built and available at `artifact_path` (default: `.build/agent.zip`). See [examples/strands-agent/](examples/strands-agent/) for a reference build.

## Usage

```bash
cd data-science/us-east-1/bedrock-agentcore/

# Build the example agent (or bring your own zip)
cd examples/strands-agent && bash build.sh && cd ../..

leverage tf init
leverage tf plan
leverage tf apply
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `artifact_path` | `.build/agent.zip` | Path to the agent deployment zip (relative to layer) |
| `runtime_name` | `PYTHON_3_12` | AgentCore runtime (`PYTHON_3_10` / `3_11` / `3_12` / `3_13`) |
| `entry_point` | `["agent.py"]` | Entrypoint file(s) for the agent |
| `runtime_description` | `"...deployed via Leverage"` | Runtime description |
| `endpoint_description` | `"...deployed via Leverage"` | Endpoint description |
| `environment_variables` | `{}` | Env vars passed to the runtime |

## Design Decisions

- **Pure infrastructure** — the layer does not build agent code. Build artifacts are produced externally.
- **Direct AWSCC resources** instead of `aws-ia/agentcore/aws` module — the module (v0.0.4) requires AWS provider v6+ and has OpenTofu-incompatible validation blocks. No workarounds.
- **Code configuration** instead of container — eliminates Docker build, ECR push, and multi-step apply. Single `leverage tf apply` deploys everything. Container mode support is planned for future iterations.
- **Pre-bundled dependencies** — AgentCore does not auto-install from pyproject.toml. The agent zip must include all dependencies (see `examples/strands-agent/build.sh`).
- **IAM auth** (default) — no Cognito/JWT authorizer. Keeps the layer minimal.
- **PUBLIC network mode** — no VPC dependency for first iteration.
- **AWSCC naming**: Resource names use underscores (`bb_data_science_agentcore_runtime`) because AWSCC requires `^[a-zA-Z][a-zA-Z0-9_]{0,47}$`.
- **Python 3.12** — matches `agentcore configure` defaults and has broad library compatibility.
