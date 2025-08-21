# Project Structure

## Repository Organization

The repository follows a **multi-account, layered architecture** pattern with clear separation of concerns:

```
├── {account}/                    # Account-specific directories
│   ├── config/                   # Account configuration
│   │   ├── account.tfvars       # Account-specific variables
│   │   └── backend.tfvars       # Backend configuration
│   ├── global/                   # Global (region-independent) resources
│   └── {region}/                 # Region-specific resources
│       └── {layer}/              # Individual infrastructure layers
├── config/                       # Shared configuration
└── @doc/                        # Documentation and diagrams
```

## Account Structure

### Primary Accounts
- **management**: AWS Organizations, billing, cost management
- **security**: Security hub, compliance, monitoring, audit
- **shared**: Shared services, tools, container registry
- **network**: Networking, VPCs, transit gateway, firewall
- **apps-devstg**: Development/staging applications
- **apps-prd**: Production applications  
- **data-science**: ML/AI workloads, data lake, analytics

## Layer Patterns

### Standard Layer Structure
Each layer follows consistent patterns:
```
layer-name/
├── config.tf                    # Provider and backend configuration
├── common-variables.tf          # Symlinked shared variables
├── locals.tf                    # Local value calculations
├── variables.tf                 # Layer-specific input variables
├── outputs.tf                   # Output definitions
├── main.tf or {resource}.tf     # Resource-specific files
├── .terraform.lock.hcl          # OpenTofu/Terraform lock file
└── DEPLOYMENT.md               # Layer-specific deployment docs (optional)
```

### Module Sources
Modules are sourced from GitHub repositories with specific version tags:
```hcl
source = "github.com/binbashar/tofu-aws-tfstate-backend.git?ref=v1.0.29"
```

### Configuration Hierarchy
1. **Global config** (`config/common.tfvars`) - Project-wide settings
2. **Account config** (`{account}/config/account.tfvars`) - Account-specific settings  
3. **Backend config** (`{account}/config/backend.tfvars`) - Terraform backend settings
4. **Layer-specific** - Local variables and overrides

## Naming Conventions

### Directories
- Account names: lowercase with hyphens (`apps-devstg`, `data-science`)
- Regions: AWS region format (`us-east-1`, `us-east-2`)
- Layers: descriptive names with hyphens (`base-network`, `security-keys`)

### Resources
- Project prefix: `${var.project}-${var.environment}-{resource}`
- Tags: At minimum `Project`, `Environment`, `Layer`, `Owner`, `CostCenter`, and `ManagedBy=OpenTofu`

### Files
- Configuration: `*.tf` for Terraform, `*.tfvars` for variables
- Secrets: `secrets.enc` (encrypted), `secrets.dec.tf` (decrypted; must be .gitignored — never commit)
- Documentation: `README.md`, `NOTES.md`

## Key Directories

### Root Level
- `@bin/`: Build scripts and makefiles
- `@doc/`: Architecture diagrams and documentation
- `config/`: Shared configuration templates

### Special Markers
- `--` suffix: Indicates disabled/optional layers
- `common-variables.tf`: Symlinked shared variable definitions

## Remote State Management

Layers reference each other via Terraform remote state:
- Backend: S3 bucket per account
- Locking: DynamoDB table per account
- State keys: `{account}/{layer}/terraform.tfstate`

## Development Workflow

1. **Navigate to specific layer directory** - Always work from layer directories, not root
2. **Use Leverage CLI** - Use `leverage tofu` or `leverage tf` (shorthand) for all operations
3. **Check dependencies** - Run `leverage run layer_dependency` (from layer directory) before major changes
4. **Follow standard workflow** - init → plan → apply → validate
5. **Maintain consistent structure** - Follow established file patterns and naming conventions
6. **Cost awareness** - Run `make infracost-breakdown` before significant changes
7. **Multi-account respect** - Changes in one account may affect others via remote state

## Key Development Rules

### Always Use Leverage CLI
- **Never use direct tofu/terraform commands** - Always use `leverage tofu` or `leverage tf`
- **Work from layer directories** - Commands must be run from specific layer paths
- **Respect container environment** - All operations run in controlled Docker containers

### State Management Best Practices
- Each account has isolated S3 backend with DynamoDB locking
- State files stored per layer: `{account}/{layer}/terraform.tfstate`
- Remote state references enable cross-layer data sharing
- Force unlock only when necessary: `leverage tf shell` then `tofu force-unlock -force <LOCK_ID>`