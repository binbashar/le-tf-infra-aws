# OpenTofu Best Practices for Binbash Leverage Reference Architecture

## Core Principles

### Code Structure
- Write concise, well-structured OpenTofu code with clear examples
- Organize resources into reusable, versioned modules
- Use variables and locals for all configurable values; avoid hardcoding
- Structure files logically: main config, locals, variables, outputs, modules

### Leverage CLI Usage
- **Always use the Leverage CLI** (`leverage tofu <command>` or `leverage tf <command>`) for all OpenTofu operations
- This ensures consistency, automation, and alignment with Leverage best practices
- Never use direct `tofu` or `terraform` commands - always go through Leverage CLI

## Module Guidelines

### Module Preference Hierarchy
1. **Always prefer Binbash Leverage modules** - Check the [module Makefile](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile) first
2. Only create new modules if no suitable Leverage module exists
3. Contribute improvements upstream when possible

### Module Best Practices
- Use outputs to pass data between modules
- Follow semantic versioning for modules
- Document modules with examples and clear input/output definitions
- Split code into reusable modules; avoid duplication

## OpenTofu Configuration Standards

### File Organization
- Follow the [Leverage AWS directory structure](https://leverage.binbash.co/user-guide/ref-architecture-aws/dir-structure)
- Standard layer structure:
  ```
  layer-name/
  ├── config.tf           # Provider and backend configuration
  ├── common-variables.tf # Symlinked common variables
  ├── locals.tf          # Local value calculations
  ├── variables.tf       # Layer-specific variables
  ├── outputs.tf         # Output definitions
  └── *.tf              # Resource-specific files
  ```

### Code Quality
- Always run `leverage tf fmt` for formatting
- Use `leverage tf validate` for validation
- Use tools like `tflint` or `terrascan` for linting
- Lock provider versions for consistency
- Configure pre-commit hooks to run fmt/validate/lint locally (e.g., `tofu fmt`, `tofu validate`, `tflint`, `terrascan`)

### Backend Configuration
- Use remote backends (S3) with state locking and encryption
- Each account has its own S3 backend with DynamoDB locking
- State files stored per layer: `{account}/{layer}/terraform.tfstate`

## Security Practices

### Sensitive Data Management
- Never hardcode sensitive values; prefer AWS Secrets Manager or AWS Systems Manager Parameter Store
- Avoid long-lived environment variables for secrets; if used in CI, ensure strict redaction and short TTLs
- Store sensitive data in AWS Secrets Manager ([example layer](https://github.com/binbashar/le-tf-infra-aws/tree/master/apps-devstg/us-east-1/secrets-manager))
- Enable encryption for all storage and communication
- Define access controls and security groups for each resource

### Compliance
- Follow [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected)
- Follow Leverage security guidelines
- Tag all resources for tracking and cost management

## Error Handling & Validation

### Input Validation
- Use variable validation rules
- Handle edge cases with conditionals and `null` checks
- Prefer implicit dependencies via resource/output references; use `depends_on` only when implicit dependencies are not inferred

### Resource Management
- Define resources modularly for scalability
- Use `-target` for resource-specific changes
- Limit use of `count`/`for_each` to avoid unnecessary duplication

## Performance Optimization

### Execution Efficiency
- Cache provider plugins locally
- Use targeted operations when possible
- Optimize state file size and structure

### Resource Efficiency
- Design for cost optimization
- Use appropriate resource sizing
- Implement lifecycle rules where applicable

## Testing & CI/CD Integration

### Testing Strategy
- Integrate with CI/CD (GitHub Actions, [Digger](https://digger.dev))
- Run `leverage tf plan` in CI to catch issues before apply
- Use `leverage tf test` for module unit tests
- Automate tests for critical infrastructure (network, IAM)

### Workflow Integration
- Reference [example workflow](https://github.com/binbashar/le-tf-infra-aws/blob/master/.github/workflows/testing-workflow.yml)
- Implement proper PR review processes
- Use automated validation in pipelines

## Key Conventions

### Resource Naming
- AWS resources: `{project}-{environment}-{resource}` (e.g., `bb-devstg-devops`)
- Use consistent naming patterns across all resources
- Follow Leverage naming conventions

### Documentation
- Document all modules and configurations with `README.md`
- Include clear examples in module documentation
- Maintain up-to-date documentation for all layers

### Version Management
- Lock provider versions
- Use semantic versioning for custom modules
- Keep dependencies up to date
- Set `required_version` (OpenTofu/Terraform) and pin `required_providers` in `config.tf`

## Review & PR Process

### Code Review Standards
- Reference Leverage docs and module sources in PR descriptions and code comments
- Ensure all changes align with Leverage conventions and AWS Well-Architected Framework
- Document any deviations from Leverage standards in code comments and PRs

### Quality Gates
- All code must pass `leverage tf validate`
- All code must be formatted with `leverage tf fmt`
- Security scanning must pass
- Cost impact must be reviewed with Infracost

## Learning Resources

### Primary Documentation
- [Terraform Registry](https://registry.terraform.io) and official docs
- Stay updated with provider-specific modules for AWS, Helm, Kubernetes, GitHub, Cloudflare
- Leverage documentation and examples

### Continuous Learning
- Follow OpenTofu and AWS provider updates
- Participate in Leverage community discussions
- Contribute back to the Leverage ecosystem