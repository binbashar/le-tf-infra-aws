# Technology Stack

## Core Technologies
- **OpenTofu**: Primary Infrastructure as Code (IaC) tool, version ~> 1.6.6 (migrated from Terraform)
- **Terraform**: Legacy support maintained, but OpenTofu is preferred
- **AWS Provider**: ~> 5.91 (updated from 4.10)
- **AWS CC Provider**: ~> 1.20 (for AWS Cloud Control API resources)
- **Python**: Build automation and custom tooling
- **Ansible Vault**: Secret encryption/decryption

## Build System & CLI Tools
- **Leverage CLI**: Primary tool for infrastructure management (supports both OpenTofu and Terraform)
- **Make**: Build automation using Makefiles
- **Infracost**: Cost estimation and breakdown analysis
- **Atlantis**: Automated Terraform/OpenTofu workflows

## Key Dependencies
- **le-dev-makefiles**: Shared makefiles library (v0.1.37)
- **Ansible**: For secret management and configuration
- **Kubernetes Provider**: ~> 2.10
- **Helm Provider**: ~> 2.5

## Common Commands

### Project Initialization
```bash
# Authenticate with AWS SSO
leverage aws sso login

# Initialize makefiles (first time setup)
make init-makefiles

# Initialize OpenTofu backend
leverage tofu init
```

### Layer Management
```bash
# Navigate to specific layer (e.g., security/global/base-identities)
cd security/global/base-identities

# Standard workflow
leverage tofu init
leverage tofu plan
leverage tofu apply
leverage tofu destroy
```

> **Note**: `leverage tf` is a shorthand alias for `leverage tofu`. Both run OpenTofu.

### Secret Management
```bash
# Decrypt secrets
leverage run decrypt

# Encrypt secrets
leverage run encrypt
```

**Note**: Never commit decrypted secrets. Re-encrypt before committing and ensure `.gitignore` covers any plaintext artifacts.

### Cost Analysis
```bash
# Generate cost breakdown (from repository root)
make infracost-breakdown
```

### Development Tools
```bash
# Format OpenTofu/Terraform code
leverage tofu fmt -recursive

# Validate configuration
leverage tofu validate

# Check plan output
leverage tofu plan -out=tfplan
```

### Analysis and Dependencies
```bash
# Run custom Python tasks
leverage run <task>

# Analyze layer dependencies
python build.py layer_dependency
```

## Important Notes

### OpenTofu Migration
- **Primary Tool**: OpenTofu (`leverage tofu`) is now the primary IaC tool
- **Shorthand**: `leverage tf` is a shorthand alias for `leverage tofu`
- **Legacy Support**: Terraform commands still work but OpenTofu is preferred
- **Container Issues**: If encountering "/bin/tofu: no such file or directory", use shorthand commands

### AWS Cloud Control Provider
- **Blueprint Versions**: Must be numeric strings without decimals (e.g., "1" not "1.0")
- **Image Extraction**: Use valid enums: "CONTENT_MODERATION", "TEXT_DETECTION", "LOGOS"
- **Preview Services**: Some Bedrock Data Automation features may be in preview

## Configuration Management

### Variable Hierarchy
1. **Global config** (`config/common.tfvars`) - Project-wide settings
2. **Account config** (`{account}/config/account.tfvars`) - Account-specific settings  
3. **Backend config** (`{account}/config/backend.tfvars`) - OpenTofu backend settings
4. **Layer-specific** - Local variables and overrides

### State Backend
- **S3 Backend**: Each account has its own S3 bucket for state storage
- **DynamoDB Locking**: Prevents concurrent state modifications
- **State Keys**: Format `{account}/{layer}/terraform.tfstate`
- **Cross-layer References**: Remote state data sources enable layer communication

### Version Constraints (Updated)
- **OpenTofu**: ~> 1.6.6
- **AWS Provider**: ~> 5.91
- **AWS CC Provider**: ~> 1.20
- **Kubernetes Provider**: ~> 2.10
- **Helm Provider**: ~> 2.5

## Advanced Tooling & Integration

### Testing & Quality Assurance
```bash
# Linting and validation tools
leverage tofu validate
tflint  # Additional linting (when available)
terrascan  # Security scanning (when available)

# Testing workflows
leverage tofu test  # Module unit tests
```

### CI/CD Integration
- **GitHub Actions**: Automated workflows for validation and deployment
- **Digger**: CI/CD integration for OpenTofu workflows
- **Atlantis**: Pull request automation for infrastructure changes
- **Example Workflow**: [Reference implementation](https://github.com/binbashar/le-tf-infra-aws/blob/master/.github/workflows/testing-workflow.yml) and see this repo's `.github/workflows/` directory for active pipelines

### Performance & Optimization
```bash
# Targeted operations for efficiency
leverage tofu plan -target=resource.name
leverage tofu apply -target=resource.name

**Note**: Use -target sparingly; it's intended for exceptional cases and can lead to partial applies and unintended drift if misused.

# State management
leverage tofu state list
leverage tofu state show resource.name
```

### Advanced AWS Services
- **Bedrock Integration**: AI/ML workloads and document processing
- **EventBridge**: Event-driven architectures
- **Lambda**: Serverless compute integration
- **EKS/ECS**: Container orchestration platforms
- **Multi-region**: Primary (us-east-1) and DR (us-east-2) deployments

## Expert-Level Capabilities

### Infrastructure Specializations
- **Cloud Architecture**: Multi-account AWS organization patterns
- **DevOps**: CI/CD pipelines and automation
- **Security**: Compliance, encryption, and access controls
- **Data Engineering**: Data lakes, analytics, and ML pipelines
- **GenAI**: Bedrock integration and AI workload deployment
- **Container Orchestration**: EKS and ECS management

### Troubleshooting & Debugging
```bash
# State lock issues
echo "tofu force-unlock -force <LOCK_ID>" | leverage tofu shell

# Container debugging
leverage tofu shell  # Interactive container access

# Dependency analysis
python build.py layer_dependency
```