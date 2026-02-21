# Strands Agent Example

Minimal [Strands](https://github.com/strands-agents/strands-agents-python) agent for Bedrock AgentCore. Use this as a starting point or replace it with your own agent.

## Files

| File | Purpose |
|------|---------|
| `agent.py` | Agent entrypoint using `BedrockAgentCoreApp` |
| `pyproject.toml` | Python dependencies |
| `build.sh` | Builds the deployment zip for AgentCore |

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

## Customize

- Edit `agent.py` to change the agent logic
- Edit `pyproject.toml` to add/change dependencies
- Rebuild with `bash build.sh` and redeploy with `leverage tf apply`
