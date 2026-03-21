# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**Binbash Leverage Reference Architecture** -- a multi-account AWS infrastructure codebase using OpenTofu, orchestrated by the [Leverage CLI](https://github.com/binbashar/leverage). Each AWS account is a top-level directory, each functional concern is an isolated "layer" with its own state file.

### Git Commit Practices
- **DO NOT include AI tool attributions** in commit messages (no "Co-Authored-By: Claude" or similar)
- **DO NOT add Claude Code watermarks** or references to AI assistance in commits
- Keep commit messages professional and focused on the technical changes
- Never commit `tfplan` binary files or test PDF/binary documents

## Essential Commands

All OpenTofu operations **must** go through Leverage CLI. Never run `tofu` or `terraform` directly.

```bash
# Authenticate
leverage aws sso login

# Always work from a layer directory
cd {account}/{region}/{layer}    # e.g., shared/us-east-1/base-network

# Core workflow
leverage tf init
leverage tf plan
leverage tf apply

# Validation (run before commits)
leverage tf fmt -recursive
leverage tf validate

# Layer dependency analysis (run from a layer directory)
leverage run layer_dependency

# Secret management (Ansible Vault, run from a layer directory)
leverage run decrypt          # decrypts secrets.enc -> secrets.dec.tf
leverage run encrypt          # encrypts secrets.dec.tf -> secrets.enc, deletes plaintext

# State operations
leverage tf state list
leverage tf state show resource.name
echo "tofu force-unlock -force <LOCK_ID>" | leverage tf shell

# Cost analysis (from repo root)
make infracost-breakdown

# First-time setup
make init-makefiles
```

## Architecture

### Directory Layout

```
{account}/{region}/{layer}/      # e.g., apps-devstg/us-east-1/base-network/
```

**Accounts**: `management`, `security`, `network`, `shared`, `apps-devstg`, `apps-prd`, `data-science`
**Regions**: `global` (IAM, Route53), `us-east-1` (primary), `us-east-2` (DR)

Directories ending with ` --` suffix (space-dash-dash) are **disabled/optional layers** excluded from active deployment and Atlantis autodiscover.

### Variable and Configuration Hierarchy

Variables flow through three levels, all auto-loaded by Leverage CLI:

1. **`config/common.tfvars`** (repo root) -- project-wide: project name (`bb`), account IDs, SSO config, regions
2. **`{account}/config/account.tfvars`** -- sets `environment` (matches account name) and `sso_role`
3. **`{account}/config/backend.tfvars`** -- backend S3 bucket, profile (`bb-{account}-devops`), DynamoDB table

Every layer symlinks `common-variables.tf -> ../../../config/common-variables.tf` to share a single variable definition file across 100+ layers. This file defines the standard variables (`region`, `profile`, `bucket`, `project`, `environment`, `accounts`, etc.) and a `locals` block that auto-detects `current_region` and `layer_name` from `path.cwd`.

### Cross-Layer Dependencies (Remote State)

Layers reference each other via `data "terraform_remote_state"` blocks, typically defined in `config.tf`. The pattern:

```hcl
data "terraform_remote_state" "base-network" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "{account}/{layer}/terraform.tfstate"
  }
}
```

For cross-account references, the profile and bucket change:
```hcl
profile = "${var.project}-{other-account}-devops"
bucket  = "${var.project}-{other-account}-terraform-backend"
```

Complex layers (e.g., `shared/us-east-1/base-network`) use `for_each` over locals maps to manage multiple remote state dependencies from different accounts. Check `locals.tf` for these maps and `config.tf` for the data sources.

Use `leverage run layer_dependency` from any layer directory to see its dependency graph.

### Cross-Account Provider Pattern

Layers needing cross-account access define aliased providers in `config.tf`:

```hcl
provider "aws" {
  region  = var.region
  profile = var.profile                           # current account
}
provider "aws" {
  alias   = "apps-devstg"
  region  = var.region
  profile = "${var.project}-apps-devstg-devops"   # cross-account
}
```

Profile naming: `{project}-{account}-devops` (e.g., `bb-shared-devops`, `bb-network-devops`).

### Layer File Structure

```
layer-name/
  config.tf              # Providers, backend key, remote state data sources
  common-variables.tf    # Symlink to config/common-variables.tf
  locals.tf              # Tags, computed values, remote state config maps
  variables.tf           # Layer-specific variables
  outputs.tf             # Outputs (consumed by other layers via remote state)
  main.tf or *.tf        # Resources
```

The `locals.tf` always includes a standard tags block:
```hcl
locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name    # auto-detected from path
  }
}
```

## Key Conventions

- **Naming**: AWS resources follow `{project}-{environment}-{resource}` (e.g., `bb-shared-vpc`)
- **State keys**: `{account}/{layer-path}/terraform.tfstate` in the backend config
- **Module sources**: GitHub pinned refs -- `github.com/binbashar/{module}.git?ref=v1.2.3`
- **Module-first approach**: Always check [Binbash module library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile) before writing custom resources
- **Tags**: Every resource must include the standard `local.tags` block

## Project Configuration

- **`build.env`** (repo root): `PROJECT=bb`, `TERRAFORM_IMAGE_TAG=1.9.1-tofu-0.3.0` -- configures the Leverage CLI Docker image
- **`atlantis.yaml`**: Autodiscover enabled with `config/*` ignored; automerge and delete-source-branch on merge
- **`infracost.yml`**: Defines cost analysis entries for every layer across all accounts
- **`renovate.json`**: Automated dependency updates
- **`.pre-commit-config.yaml`**: Enforces `terraform_fmt`, JSON validation, trailing whitespace, private key detection

## CI/CD

- **GitHub Actions** on push to non-master branches: `test-static-code-and-linting.yml` runs `make pre-commit` (terraform fmt + pre-commit hooks)
- `terraform_fmt` hook -- always run `leverage tf fmt -recursive` before pushing
- `pretty-format-json` hook sorts keys alphabetically and autofixes -- ensure JSON files have sorted keys before pushing
- **Infracost** workflow for cost impact analysis on PRs
- **Atlantis** for automated plan/apply workflows
- Slack notifications on pipeline success/failure
- PR template at `.github/PULL_REQUEST_TEMPLATE.md` uses What? / Why? / References format

### Common GitHub Usernames
- exe -> `exequielrafaela`, OJ (Diego Ojeda) -> `diego-ojeda-binbash`, Alex -> `Alx-binbash`

## Troubleshooting

### Docker Container Issues
If you encounter errors like "stat /bin/tofu: no such file or directory":
- Use `leverage tf` instead of `leverage tofu` -- maps to OpenTofu and avoids container path issues

### AWS CC Provider Issues
When working with AWS Cloud Control API resources (awscc_*):
- Blueprint version must be numeric string without decimals (e.g., "1" not "1.0")
- Image extraction categories must use valid enums: "CONTENT_MODERATION", "TEXT_DETECTION", "LOGOS"
- Some Bedrock Data Automation features may be in preview

### Bedrock AgentCore (data-science/us-east-1/bedrock-agentcore)
- Uses direct AWSCC resources (not aws-ia module) -- see layer CLAUDE.md for details
- Two AWS CLI services: `bedrock-agentcore` (invoke) and `bedrock-agentcore-control` (CRUD)
- `bb-data-science-devops` profile only works inside leverage Docker; use SSO profile for direct CLI calls

## References

- [Leverage Documentation](https://leverage.binbash.co) -- primary source of truth
- [Leverage CLI](https://github.com/binbashar/leverage) ([PyPI](https://pypi.org/project/leverage))
- [Binbash Module Library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected)
