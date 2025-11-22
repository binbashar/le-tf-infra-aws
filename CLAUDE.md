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
- Always run `leverage tf fmt` for formatting and `leverage tf validate` for validation

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

## Essential Commands

### Authentication and Setup
```bash
# Authenticate with AWS SSO
leverage aws sso login

# Initialize makefiles (first time setup)
make init-makefiles

# Initialize OpenTofu for a specific layer (run from layer directory)
leverage tofu init
# Or using shorthand (preferred)
leverage tf init
```

### Development Workflow
```bash
# Navigate to specific layer directory (REQUIRED - always work from layer directories)
cd {account}/{region}/{layer}  # e.g., shared/us-east-1/k8s-eks

# Plan changes (use shorthand 'tf' for OpenTofu)
leverage tf plan

# Apply changes
leverage tf apply

# Destroy infrastructure
leverage tf destroy

# Cost analysis (from repository root)
make infracost-breakdown

# Run custom Python tasks
leverage run <task>

# Analyze layer dependencies
python build.py layer_dependency
```

### Testing and Validation
```bash
# Validate configuration
leverage tf validate

# Format code (recursive)
leverage tf fmt -recursive

# Check plan output
leverage tf plan -out=tfplan

# Run tests
leverage tf test

# Open shell in container for debugging
leverage tf shell
```

### Secret Management
```bash
# Decrypt secrets
leverage run decrypt

# Encrypt secrets
leverage run encrypt
```

### Advanced Operations
```bash
# Targeted operations for efficiency
leverage tf plan -target=resource.name
leverage tf apply -target=resource.name

# State management
leverage tf state list
leverage tf state show resource.name

# Force unlock state (use with caution)
echo "tofu force-unlock -force <LOCK_ID>" | leverage tf shell
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

### File Structure per Layer
Each layer follows this standardized pattern:
```
layer-name/
├── config.tf                    # Provider and backend configuration
├── common-variables.tf          # Symlinked shared variables
├── locals.tf                    # Local value calculations
├── variables.tf                 # Layer-specific input variables
├── outputs.tf                   # Output definitions
├── main.tf or {resource}.tf    # Resource-specific files
├── .terraform.lock.hcl          # OpenTofu/Terraform lock file
└── DEPLOYMENT.md               # Layer-specific deployment docs (optional)
```

## Key Conventions

### OpenTofu/Terraform State Management
- Each account has its own S3 backend with DynamoDB locking
- State files stored per layer: `{account}/{layer}/terraform.tfstate`
- Remote state references enable cross-layer data sharing
- Force unlock only when necessary: `echo "tofu force-unlock -force <LOCK_ID>" | leverage tf shell`

### Module Sources
Modules are sourced from GitHub repositories:
```hcl
source = "github.com/binbashar/tofu-aws-tfstate-backend.git?ref=v1.0.29"
```

### Naming Conventions
- AWS resources: `{project}-{environment}-{resource}` (e.g., `bb-shared-devops`)
- Project prefix: `${var.project}-${var.environment}-{resource}`
- AWS profiles follow cross-account access patterns
- Directories ending with `--` suffix indicate disabled/optional layers
- Tags: Consistent tagging with `Terraform`, `Environment`, `Layer`

### Variable Management
- Common variables in `config/common.tfvars`
- Account-specific in `{account}/config/account.tfvars`
- Backend config in `{account}/config/backend.tfvars`

### Version Constraints
- **OpenTofu**: ~> 1.6.6 (primary IaC tool)
- **Terraform**: ~> 1.6.6 (legacy support)
- **AWS Provider**: ~> 5.100
- **AWS CC Provider**: <none found – verify usage or remove>
- **Kubernetes Provider**: ~> 2.37
- **Helm Provider**: ~> 2.17
## Important Development Notes

### Critical Rules
1. **Always use Leverage CLI** - Never use direct `tofu` or `terraform` commands, always use `leverage tf` (shorthand for OpenTofu)
2. **Always work from specific layer directories** - Commands must be run from layer paths, not repository root
3. **Check layer dependencies** before making changes using `python build.py layer_dependency`
4. **Respect multi-account boundaries** - Changes in one account may affect others through remote state
5. **Follow existing patterns** - Each layer has consistent structure and naming conventions
6. **Module-first approach** - Always check [Binbash module library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile) before creating custom solutions

### Best Practices
7. **Cost awareness** - Run `make infracost-breakdown` before applying significant changes
8. **Security-first** - Follow AWS Well-Architected Framework and Leverage security guidelines
9. **Documentation** - Reference official [Leverage Documentation](https://leverage.binbash.co) for guidance
10. **Testing** - Use `leverage tf test` for module unit tests and integrate with CI/CD
11. **Code quality** - Always run `leverage tf fmt` and `leverage tf validate` before commits
12. **Atlantis integration** - The repository uses Atlantis for automated OpenTofu/Terraform workflows

## Common Troubleshooting

### Docker Container Issues
If you encounter errors like "stat /bin/tofu: no such file or directory":
- Use the shorthand commands: `leverage tf` instead of `leverage tofu`
- This maps to OpenTofu and avoids container path issues

### AWS CC Provider Issues
When working with AWS Cloud Control API resources (awscc_*):
- Blueprint version must be numeric string without decimals (e.g., "1" not "1.0")
- Image extraction categories must use valid enums: "CONTENT_MODERATION", "TEXT_DETECTION", "LOGOS"
- Some Bedrock Data Automation features may be in preview

### State Lock Issues
If encountering state lock errors:
```bash
# Force unlock (use with caution)
echo "tofu force-unlock -force <LOCK_ID>" | leverage tf shell
```

### Debugging
For interactive debugging:
```bash
# Open shell in container
leverage tf shell
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