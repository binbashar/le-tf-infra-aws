# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **Binbash Leverage Reference Architecture** - a comprehensive OpenTofu-based AWS infrastructure solution that implements enterprise-grade cloud architecture patterns.

### Purpose
- Provides a complete multi-account AWS infrastructure setup using OpenTofu (migrated from Terraform)
- Implements security, networking, and application layers following AWS best practices
- Serves as a reference implementation for scalable cloud infrastructure
- Supports multiple environments (development, staging, production) across different AWS accounts

### Key Features
- **Multi-account AWS organization structure**: management, security, shared, network, apps-devstg, apps-prd, data-science
- **Layered architecture** with clear separation of concerns and dependencies
- **Automated infrastructure deployment** using Leverage CLI with OpenTofu
- **Built-in security compliance** and monitoring across all layers
- **Container orchestration support** (ECS, EKS) for modern workloads
- **Data lake and analytics capabilities** including ML/AI workloads with AWS Bedrock
- **Comprehensive backup and disaster recovery** strategies
- **Cost optimization** with built-in Infracost integration
- **Atlantis integration** for automated workflow management

### Advanced Capabilities
- **AWS Bedrock integration** for AI/ML workloads and document processing
- **Event-driven architectures** using EventBridge, Lambda, and SQS
- **Multi-region deployment** support (us-east-1 primary, us-east-2 DR)
- **Comprehensive monitoring** with CloudWatch, logging, and alerting
- **Security-first approach** with KMS encryption, IAM least privilege, and audit trails

## Core Principles & Best Practices

### OpenTofu/Terraform Best Practices
- Write concise, well-structured OpenTofu code with clear examples
- Organize resources into reusable, versioned modules
- Use variables and locals for all configurable values; avoid hardcoding
- Structure files logically: main config, locals, variables, outputs, modules
- Follow the [Leverage AWS directory structure](https://leverage.binbash.co/user-guide/ref-architecture-aws/dir-structure)
- Always run `leverage tofu fmt` for formatting and `leverage tofu validate` for validation

### Module Guidelines
- **Always prefer Binbash Leverage modules** - Check the [module library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile) first
- Only create new modules if no suitable Leverage module exists
- Use outputs to pass data between modules
- Follow semantic versioning for modules
- Document modules with examples and clear input/output definitions

### Security Practices
- Never hardcode sensitive values; use AWS Secrets Manager or environment variables
- Enable encryption for all storage and communication
- Define access controls and security groups for each resource
- Follow [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected)
- Store sensitive data in AWS Secrets Manager ([example layer](https://github.com/binbashar/le-tf-infra-aws/tree/master/apps-devstg/us-east-1/secrets-manager))

### Git Commit Practices
- **DO NOT include AI tool attributions** in commit messages (no "Co-Authored-By: Claude" or similar)
- **DO NOT add Claude Code watermarks** or references to AI assistance in commits
- Keep commit messages professional and focused on the technical changes
- Never commit `tfplan` binary files or test PDF/binary documents

### Sensitive Information in PRs and Comments
- **Never expose AWS account IDs** in PR descriptions, comments, or plan outputs — replace with `<ACCOUNT_NAME_ACCOUNT_ID>` (e.g., `<SECURITY_ACCOUNT_ID>`)
- **Never expose AWS access key IDs or secrets** — replace entirely with `***`
- **Obfuscate PGP keys, ARNs with account IDs, and any IAM credential identifiers** before posting plan outputs
- When posting `leverage tofu plan` output to PRs, always review and redact sensitive values before sharing

## Essential Commands

### Authentication and Setup
```bash
# Authenticate with AWS SSO
leverage aws sso login

# Initialize makefiles (first time setup)
make init-makefiles

# Initialize OpenTofu for a specific layer (run from layer directory)
leverage tofu init
```

### Development Workflow
```bash
# Navigate to specific layer directory (REQUIRED - always work from layer directories)
cd {account}/{region}/{layer}  # e.g., shared/us-east-1/k8s-eks

# Plan changes (use shorthand 'tf' for OpenTofu)
leverage tofu plan

# Apply changes
leverage tofu apply

# Destroy infrastructure
leverage tofu destroy

# Cost analysis (from repository root)
make infracost-breakdown

# Run custom Python tasks
leverage run <task>

# Analyze layer dependencies (run from a layer directory)
leverage run layer_dependency
```

### Testing and Validation
```bash
# Validate configuration
leverage tofu validate

# Format code (recursive)
leverage tofu fmt -recursive

# Run tests
leverage tofu test

# Open shell in container for debugging
leverage tofu shell
```

### Secret Management
```bash
# Decrypt secrets (Ansible Vault, run from a layer directory)
leverage run decrypt          # decrypts secrets.enc -> secrets.dec.tf

# Encrypt secrets
leverage run encrypt          # encrypts secrets.dec.tf -> secrets.enc, deletes plaintext
```

### Advanced Operations
```bash
# Targeted operations for efficiency
leverage tofu plan -target=resource.name
leverage tofu apply -target=resource.name

# State management
leverage tofu state list
leverage tofu state show resource.name

# Force unlock state (use with caution)
echo "tofu force-unlock -force <LOCK_ID>" | leverage tofu shell
```

## Architecture Overview

### Account Structure
The repository follows a multi-account AWS organization pattern:
- **management/** - AWS Organizations, billing, cost management, SSO
- **security/** - Security hub, compliance, monitoring, audit trails
- **network/** - Networking infrastructure, VPCs, transit gateway, network firewall
- **shared/** - Shared services, container registry, DNS, operational tools
- **apps-devstg/** - Development/staging applications and services
- **apps-prd/** - Production applications and services
- **data-science/** - ML/AI workloads, data lake, analytics, Bedrock integration

### Regional Organization
Each account has:
- **global/** - Global resources (IAM, Route53)
- **us-east-1/** - Primary region (North Virginia)
- **us-east-2/** - Secondary region (Ohio) for DR

### Layer Pattern
Within each region, resources are organized into functional layers:
- **base-identities/** - IAM users, groups, roles, policies
- **base-network/** - VPC, subnets, routing
- **base-tf-backend/** - Terraform state backend
- **security-*** - Security components (Config, Hub, GuardDuty)
- **databases-*** - Database resources
- **k8s-*** - Kubernetes infrastructure
- **tools-*** - Operational tools

Directories ending with a space followed by `--` suffix (e.g., `databases-mysql --`) are **disabled/optional layers** excluded from active deployment and Atlantis autodiscover.

### File Structure per Layer
Each layer follows this standardized pattern:
```text
layer-name/
├── config.tf                    # Provider, backend configuration, and remote state data sources
├── common-variables.tf          # Symlinked shared variables (-> ../../../config/common-variables.tf)
├── locals.tf                    # Tags, computed values, remote state config maps
├── variables.tf                 # Layer-specific input variables
├── outputs.tf                   # Output definitions (consumed by other layers via remote state)
├── main.tf or {resource}.tf    # Resource-specific files
├── .terraform.lock.hcl          # OpenTofu/Terraform lock file
└── DEPLOYMENT.md               # Layer-specific deployment docs (optional)
```

The `locals.tf` always includes a standard tags block:
```hcl
locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name    # auto-detected from path.cwd
  }
}
```

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
    key     = "{account}/{layer-path}/terraform.tfstate"
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

## Key Conventions

### OpenTofu/Terraform State Management
- Each account has its own S3 backend with DynamoDB locking
- State files stored per layer: `{account}/{layer-path}/terraform.tfstate`
- Remote state references enable cross-layer data sharing
- Force unlock only when necessary: `echo "tofu force-unlock -force <LOCK_ID>" | leverage tofu shell`

### Module Sources
Modules are sourced from GitHub repositories:
```hcl
source = "github.com/binbashar/tofu-aws-tfstate-backend.git?ref=v1.0.29"
```

### Naming Conventions
- AWS resources: `{project}-{environment}-{resource}` (e.g., `bb-shared-devops`)
- Project prefix: `${var.project}-${var.environment}-{resource}`
- AWS profiles: `{project}-{account}-devops` (e.g., `bb-shared-devops`, `bb-network-devops`)
- Tags: Consistent tagging with `Terraform`, `Environment`, `Layer` via `local.tags`

### Version Constraints
- **OpenTofu**: >= 1.0.9 to ~> 1.6 (varies by layer; primary IaC tool)
- **AWS Provider**: ~> 3.0 to ~> 6.0 (most layers use ~> 5.0 or ~> 4.10)
- **AWSCC Provider**: ~> 1.0 (used in Bedrock/AI layers under data-science/)
- **Kubernetes Provider**: ~> 2.11 to ~> 2.23
- **Helm Provider**: ~> 2.11 to ~> 2.13

### Project Configuration Files
- **`build.env`** (repo root): `PROJECT=bb`, `TERRAFORM_IMAGE_TAG=1.9.1-tofu-0.3.0` -- configures the Leverage CLI Docker image
- **`atlantis.yaml`**: Autodiscover enabled with `config/*` ignored; automerge and delete-source-branch on merge
- **`infracost.yml`**: Defines cost analysis entries for every layer across all accounts
- **`renovate.json`**: Automated dependency updates
- **`.pre-commit-config.yaml`**: Enforces `terraform_fmt`, JSON validation, trailing whitespace, private key detection

## Important Development Notes

### Critical Rules
1. **Always use Leverage CLI** - Never use direct `tofu` or `terraform` commands, always use `leverage tofu` (or `leverage tf` shorthand)
2. **Always work from specific layer directories** - Commands must be run from layer paths, not repository root
3. **Check layer dependencies** before making changes using `leverage run layer_dependency`
4. **Respect multi-account boundaries** - Changes in one account may affect others through remote state
5. **Follow existing patterns** - Each layer has consistent structure and naming conventions
6. **Module-first approach** - Always check [Binbash module library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile) before creating custom solutions

### Best Practices
7. **Cost awareness** - Run `make infracost-breakdown` before applying significant changes
8. **Security-first** - Follow AWS Well-Architected Framework and Leverage security guidelines
9. **Documentation** - Reference official [Leverage Documentation](https://leverage.binbash.co) for guidance
10. **Testing** - Use `leverage tofu test` for module unit tests and integrate with CI/CD
11. **Code quality** - Always run `leverage tofu fmt` and `leverage tofu validate` before commits
12. **Atlantis integration** - The repository uses Atlantis for automated OpenTofu/Terraform workflows

### CI / Pre-commit
- CI job "Test and Lint" runs `make pre-commit` → `pre-commit run --all-files`
- Includes `terraform_fmt` hook — always run `leverage tofu fmt -recursive` before pushing
- `pretty-format-json` hook sorts keys alphabetically and autofixes — ensure JSON files have sorted keys before pushing
- **Infracost** workflow for cost impact analysis on PRs
- Slack notifications on pipeline success/failure
- PR template at `.github/PULL_REQUEST_TEMPLATE.md` uses What? / Why? / References format

### Common GitHub Usernames
- exe → `exequielrafaela`, OJ (Diego Ojeda) → `diego-ojeda-binbash`, Alex → `Alx-binbash`

## Common Troubleshooting

### Docker Container Issues
If you encounter errors like "stat /bin/tofu: no such file or directory":
- Use `leverage tofu` (or `leverage tf` shorthand) instead of direct `tofu` commands
- This maps to OpenTofu and avoids container path issues

### AWS CC Provider Issues
When working with AWS Cloud Control API resources (awscc_*):
- Blueprint version must be numeric string without decimals (e.g., "1" not "1.0")
- Image extraction categories must use valid enums: "CONTENT_MODERATION", "TEXT_DETECTION", "LOGOS"
- Some Bedrock Data Automation features may be in preview

### Bedrock AgentCore (data-science/us-east-1/bedrock-agentcore)
- Uses direct AWSCC resources (not aws-ia module) — see layer CLAUDE.md for details
- Two AWS CLI services: `bedrock-agentcore` (invoke) and `bedrock-agentcore-control` (CRUD)
- `bb-data-science-devops` profile only works inside leverage Docker; use SSO profile for direct CLI calls

### State Lock Issues
If encountering state lock errors:
```bash
# Force unlock (use with caution)
echo "tofu force-unlock -force <LOCK_ID>" | leverage tofu shell
```

### Debugging
For interactive debugging:
```bash
# Open shell in container
leverage tofu shell
```

## Documentation Sources

### Primary References
- **[Leverage Documentation](https://leverage.binbash.co)** - Framework usage, architecture, and best practices
- **[Leverage High-Level Characteristics](https://www.binbash.co/leverage)** - Overview of capabilities
- **[OpenTofu Reference Architecture Code](https://github.com/binbashar/le-tf-infra-aws)** - Main codebase
- **[Leverage CLI](https://github.com/binbashar/leverage)** - CLI tool ([PyPI](https://pypi.org/project/leverage))
- **[Binbash Module Library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile)** - Complete module library

### External References
- **[OpenTofu Registry](https://registry.terraform.io)** - Provider and module documentation
- **[AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected)** - AWS best practices
- **[Digger](https://digger.dev)** - CI/CD integration for OpenTofu workflows
