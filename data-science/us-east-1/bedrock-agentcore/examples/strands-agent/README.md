# Strands Agent Example

Minimal [Strands](https://github.com/strands-agents/strands-agents-python) agent for Bedrock AgentCore. Use this as a starting point or replace it with your own agent.

## Files

| File | Purpose |
|------|---------|
| `agent.py` | Agent entrypoint using `BedrockAgentCoreApp` |
| `pyproject.toml` | Python dependencies |
| `build.sh` | Builds the deployment zip for AgentCore |
| `test.sh` | Smoke test — validates runtime, endpoint, and invocation |

## Build

```bash
cd examples/strands-agent
bash build.sh
```

This produces `../../.build/agent.zip` — the artifact the Leverage layer deploys.

**Prerequisites**: [uv](https://docs.astral.sh/uv/getting-started/installation/) (auto-installed by build.sh if missing).

The build cross-compiles dependencies for ARM64 (Graviton), matching the AgentCore runtime.

## Deploy

After building, go back to the layer directory:

```bash
cd ../..
leverage tf init
leverage tf plan
leverage tf apply
```

## Test

```bash
AWS_PROFILE=<your-sso-profile> ./test.sh
```

Checks runtime `READY`, endpoint `READY`, invocation HTTP 200, and response payload. Pass `RUNTIME_ID` and `ENDPOINT_NAME` env vars to skip auto-detection from terraform state.

## Customize

- Edit `agent.py` to change the agent logic
- Edit `pyproject.toml` to add/change dependencies
- Rebuild with `bash build.sh` and redeploy with `leverage tf apply`
