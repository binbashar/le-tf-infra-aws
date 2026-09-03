<a href="https://github.com/binbashar">
    <img src="https://raw.githubusercontent.com/binbashar/le-ref-architecture-doc/master/docs/assets/images/logos/binbash-leverage-banner.png" width="1032" align="left" alt="Binbash"/>
</a>
<br clear="left"/>

<a href="https://github.com/binbashar">
    <img src="https://raw.githubusercontent.com/binbashar/.github/master/assets/images/binbash-aws-startups.png" width="1032" align="left" alt="Binbash"/>
</a>
<br clear="left"/>

# Leverage Reference Architecture: OpenTofu/Terraform AWS Infrastructure

## Overview
This repository contains all OpenTofu/Terraform configuration files used to create the Binbash Leverage Reference AWS Cloud Solutions Architecture.

## Documentation
- [Binbash Leverage Reference Architecture Official Documentation](https://leverage.binbash.co)
- [Leverage CLI](https://github.com/binbashar/leverage) ([PyPI](https://pypi.org/project/leverage/))
- [Binbash Module Library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile)

---

## Getting Started

### Prerequisites
- [Leverage CLI](https://leverage.binbash.co/user-guide/leverage-cli/installation/) (v2.2.0+)
- [OpenTofu](https://opentofu.org/docs/intro/install/) (>= 1.6)
- AWS SSO access configured for the target accounts
- [uv](https://docs.astral.sh/uv/) (recommended for Python/Leverage CLI management; also provides
  `uvx`, which the Claude Code plugin MCP servers are launched with — see
  [AI Development Configs](#ai-development-configs))

### Installation

#### Option A: Install via pip (stable)
```bash
pip install leverage
```

#### Option B: Install via uv (recommended for local development)
[uv](https://docs.astral.sh/uv/) provides fast, reproducible Python environments without conflicting with system packages.

```bash
# Create a Python 3.12 virtual environment
uv venv --python 3.12 .venv

# Install the latest Leverage CLI release (or a specific version/pre-release)
uv pip install leverage
# For pre-release/release candidates:
# uv pip install --pre leverage==2.2.0rc5

# Activate the environment
source .venv/bin/activate

# Verify
leverage --version
```

> **Note**: Leverage CLI v2.2.0+ runs OpenTofu natively (no Docker required). You need the `tofu` binary installed locally (e.g., `brew install opentofu` on macOS).

### Setup and Workflow

1. Authenticate with AWS SSO:
   ```bash
   leverage aws sso login
   ```

2. Navigate to the layer you want to work with:
   ```bash
   cd {account}/{region}/{layer}  # e.g., security/global/base-identities
   ```

3. Follow the standard workflow:
   ```bash
   leverage tofu init
   leverage tofu plan
   leverage tofu apply
   ```

4. Repeat for any desired Reference Architecture layer.

### How it works

The `backend.tfvars` injects the AWS profile name with the necessary permissions that OpenTofu uses to make changes on AWS. This profile relies on AWS SSO to assume a cross-account role for each corresponding account ([AWS IAM: users, groups, roles & policies](https://leverage.binbash.co/user-guide/ref-architecture-aws/features/identities/identities/)).

Configuration files are automatically loaded by the Leverage CLI:
- `config/common.tfvars` - Project-wide variables (project name, account IDs, SSO config)
- `{account}/config/account.tfvars` - Account-specific variables (environment, SSO role)
- `{account}/config/backend.tfvars` - Backend configuration (S3 bucket, profile, DynamoDB table)

For more details, see the [configuration files documentation](https://leverage.binbash.co/user-guide/ref-architecture-aws/configuration/#configuration-files) and the [standard workflow](https://leverage.binbash.co/user-guide/ref-architecture-aws/workflow/).

## AI Development Configs

This repository includes pre-configured settings for AI-powered development to enhance
productivity and maintain consistency across the codebase. **[Claude Code](CLAUDE.md) is the
team's standard AI development tool** — it is the only AI tooling configuration maintained
here.

### Claude Code

- **[Claude Code](CLAUDE.md)** - Anthropic's AI coding assistant
  - [`CLAUDE.md`](CLAUDE.md) - Project instructions and context for Claude
  - [`.claude/agents/`](.claude/agents/) - Specialized agent definitions (architect, security, terraform-layer, etc.)
  - [`.claude/settings.json`](.claude/settings.json) - Enabled plugins and the `bb-ai-marketplace` tag pin
  - [`.mcp.json`](.mcp.json) - Root-level MCP server configurations (AWS API, AWS Documentation)

### Usage

These configurations are discovered when you open the project in Claude Code. `CLAUDE.md` and
`.claude/agents/` load automatically, but the **project-scoped MCP servers in `.mcp.json`
require explicit approval before first use** — until approved they show as pending in
`claude mcp list`. The `aws-api` server additionally needs valid credentials for the
`bb-shared-devops` profile (`leverage aws sso login`), and is restricted to read-only AWS
operations via `READ_OPERATIONS_ONLY`.

They provide:
- Context-aware code suggestions aligned with Leverage best practices
- AWS- and OpenTofu/Terraform-specific assistance
- Consistent code formatting and structure guidelines
- Direct access to AWS documentation and the AWS API

### Plugins

[`.claude/settings.json`](.claude/settings.json) enables a set of Claude Code plugins and pins
[`binbashar/bb-ai-marketplace`](https://github.com/binbashar/bb-ai-marketplace) to a **released
tag** — adopting a newer plugin version is a deliberate bump of that pin, never a branch that
moves under us. Plugins that bundle an MCP server (`aws-cost-estimation`, `aws-finops`) launch it
with `uvx`, so [uv](https://docs.astral.sh/uv/) must be installed, and they need a Claude Code
restart plus a one-time per-server trust prompt before first use.

### AWS cost analysis (FinOps)

The **`aws-finops`** plugin analyses *actual* AWS spend from the Organizations management (payer)
account: `/aws-finops-investigate` (baseline + month-over-month deltas, anomaly triage, tag
hygiene, forecast vs budget) and `/aws-finops-optimize` (right-sizing, Savings Plans coverage,
per-service waste). Reports land in [`docs/finops/`](docs/finops/) and are committed, so each run
can be diffed against the last.

Setup, the AWS-side prerequisites this repo provisions, and how to launch a session against the
management profile: [`docs/finops/README.md`](docs/finops/README.md).

> Not to be confused with `make infracost-breakdown` or the `aws-cost-estimation` plugin, which
> price a *proposed* change before it is applied.

### Learn More

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)

## AI-Driven SDLC

Every PR is reviewed by **CodeRabbit AI** and **Gemini Code Assist** (both
auto-trigger on open / sync), gated by CI checks (`Test and Lint`, `Infracost`,
`GitGuardian`), and can be inspected on demand by **`@claude`** — which routes
through **Amazon Bedrock** (Anthropic Claude Sonnet 4.6) rather than the public
Anthropic API, so prompts and code stay inside our `apps-prd` AWS account.

See [`docs/ai-sdlc/`](docs/ai-sdlc/) for the full workflow, configuration knobs,
and architecture diagrams.

### Claude Code on AWS Bedrock (local sessions)

Local Claude Code sessions can also route through **Amazon Bedrock** in the
`data-science` account on demand — via a `claude-bedrock` launcher that flips a
single session to Bedrock while plain `claude` keeps using the native Anthropic
API. Setup, model entitlements/quotas, and troubleshooting:
[`docs/ai-sdlc/claude-code-bedrock.md`](docs/ai-sdlc/claude-code-bedrock.md).

## Leverage CLI Reference

### Project-wide commands
```bash
leverage --help               # Show all commands
leverage --version            # Show version
leverage aws sso login        # Authenticate with AWS SSO
leverage run <task>           # Run a build.py task (e.g., layer_dependency, decrypt, encrypt)
```

### Layer commands (run from a layer directory)
```bash
leverage tofu init              # Initialize the layer
leverage tofu plan              # Preview changes
leverage tofu apply             # Apply changes
leverage tofu destroy           # Destroy infrastructure
leverage tofu format            # Format code (always recursive)
leverage tofu format -check     # Check formatting without rewriting
leverage tofu validate          # Validate configuration
```

> `leverage tf` is a shorthand alias for `leverage tofu`. Both run OpenTofu.
>
> The wrapper exposes only a curated subset of subcommands: `apply`, `destroy`, `force-unlock`,
> `format`, `import`, `init`, `output`, `plan`, `refresh-credentials`, `validate`,
> `validate-layout`, `version`. Note it is `format`, **not** `fmt` — and `format` is already
> recursive, being equivalent to `tofu fmt -recursive`. See the
> [leverage tofu reference](https://leverage.binbash.co/user-guide/leverage-cli/reference/tofu/tofu/).
> That page does not currently cover `force-unlock` or `refresh-credentials`; the list above comes
> from `leverage tofu --help` on the pinned CLI, which is the authority.
>
> For anything else — `state`, `show`, `console`, `providers`, `workspace`, `graph`, `get`, `test` —
> run the native `tofu` binary from the layer directory, loading the AWS profile from the layer's
> `config/backend.tfvars`:
>
> ```bash
> tofu state list                 # List resources in state
> tofu state show <res>           # Show a specific resource in state
> ```

## Release Management
### [Reference Architecture | Releases](https://github.com/binbashar/le-tf-infra-aws/releases)
