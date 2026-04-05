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
- [uv](https://docs.astral.sh/uv/) (recommended for Python/Leverage CLI management)

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

This repository includes pre-configured settings for AI-powered development tools to enhance productivity and maintain consistency across the codebase.

### Supported IDE/AI Tools

- **[Cursor IDE](.cursor/)** - AI-first code editor with project-specific rules
  - [`.cursor/rules/`](.cursor/rules/) - Markdown rules for OpenTofu/Terraform best practices
  - [`.cursor/mcp.json`](.cursor/mcp.json) - MCP server configurations for AWS and OpenTofu/Terraform documentation

- **[Kiro IDE](.kiro/)** - AI development environment with steering documents
  - [`.kiro/steering/`](.kiro/steering/) - Comprehensive documentation about the project structure, tech stack, and best practices
  - [`.kiro/settings/mcp.json`](.kiro/settings/mcp.json) - MCP configurations for enhanced AWS/OpenTofu/Terraform support

- **[Claude Code](CLAUDE.md)** - Anthropic's AI coding assistant
  - [`CLAUDE.md`](CLAUDE.md) - Project instructions and context for Claude
  - [`.claude/agents/`](.claude/agents/) - Specialized agent definitions (architect, security, terraform-layer, etc.)
  - [`.mcp.json`](.mcp.json) - Root-level MCP server configurations (AWS Core, AWS Documentation, Terraform)

### Usage

These configurations are automatically loaded when you open the project in the respective IDE/tool. They provide:
- Context-aware code suggestions aligned with Leverage best practices
- AWS and OpenTofu/Terraform specific assistance
- Consistent code formatting and structure guidelines
- Direct access to AWS documentation and OpenTofu/Terraform registry

### Learn More

- [Cursor Documentation](https://cursor.sh/docs)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)

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
leverage tofu fmt               # Format code
leverage tofu validate          # Validate configuration
leverage tofu state list        # List resources in state
leverage tofu state show <res>  # Show a specific resource in state
```

> `leverage tf` is a shorthand alias for `leverage tofu`. Both run OpenTofu.

## Release Management
### [Reference Architecture | Releases](https://github.com/binbashar/le-tf-infra-aws/releases)
