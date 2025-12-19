# Claude Code Specialized Agents Guide

This guide helps Claude intelligently route requests to the most appropriate specialized agent based on context analysis.

## Available Specialized Agents

### 1. security-compliance
**Use for**: Security layers, compliance, IAM, KMS, secrets management
- **Layer patterns**: `*/secrets-manager/*`, `*/security-*/*`, `*/base-identities/*`, `*/iam/*`, `*/kms/*`
- **Keywords**: security, compliance, secrets, iam, kms, guardduty, securityhub, encryption, certificates
- **Expertise**: AWS security services, IAM policies, KMS encryption, CIS compliance, security monitoring

### 2. cost-optimization
**Use for**: Cost analysis, billing, financial governance, resource optimization
- **Layer patterns**: `*/cost-*/*`, `management/*/billing/*`, `*/notifications/*`
- **Keywords**: cost, billing, infracost, pricing, budget, tagging, optimization, financial
- **Expertise**: Infracost analysis, tagging strategies, resource sizing, cost monitoring, billing alerts

### 3. terraform-layer
**Use for**: General OpenTofu/Terraform operations, infrastructure layers
- **Layer patterns**: `**/*.tf`, `*/base-*/*`, `*/network/*`, `*/databases-*/*`, `*/k8s-*/*`
- **Keywords**: terraform, tofu, infrastructure, layer, module, provider, resource, leverage
- **Expertise**: Layer creation, OpenTofu operations, Leverage CLI, backend configuration, testing

### 4. feature-implementation
**Use for**: New feature development, enhancements, requirements implementation
- **Layer patterns**: `**/feat-*`, `**/feature-*`, `**/enhancement-*`, `**/new-*`
- **Keywords**: feature, enhancement, implement, develop, build, create, add, new, functionality
- **Expertise**: Feature development, architecture design, requirement analysis, implementation planning

### 5. issue-fix
**Use for**: Bug fixes, troubleshooting, error resolution
- **Layer patterns**: `**/fix-*`, `**/bug-*`, `**/hotfix-*`, `**/patch-*`
- **Keywords**: fix, bug, issue, error, problem, broken, fail, debug, resolve, troubleshoot
- **Expertise**: Debugging, error analysis, problem resolution, hotfix implementation, testing fixes

### 6. documentation
**Use for**: Documentation updates, README files, guides, knowledge management
- **Layer patterns**: `**/*.md`, `**/docs/*`, `**/README*`, `**/CHANGELOG*`, `**/DEPLOYMENT*`
- **Keywords**: documentation, docs, readme, guide, manual, instructions, tutorial, explain
- **Expertise**: Technical writing, documentation structure, user guides, API documentation, examples

### 7. dependency-update
**Use for**: Dependency management, version updates, security patches
- **Layer patterns**: `**/renovate*`, `**/requirements*`, `**/versions.tf`, `**/.terraform.lock.hcl`
- **Keywords**: dependency, update, upgrade, version, renovate, dependabot, bump, security patch
- **Expertise**: Dependency analysis, version compatibility, security updates, automation tools

## Layer Type Examples

### Security Layers → security-compliance
- `apps-devstg/us-east-1/secrets-manager/`
- `security/us-east-1/security-base/`
- `shared/us-east-1/security-keys/`
- `management/global/base-identities/`

### Infrastructure Layers → terraform-layer
- `apps-devstg/us-east-1/k8s-eks-demoapps/`
- `network/us-east-1/base-network/`
- `shared/us-east-1/databases-aurora/`
- `data-science/us-east-1/base-tf-backend/`

### Cost Management → cost-optimization
- `management/us-east-1/notifications/` (cost alerts)
- `management/global/cost-mgmt/`
- Any layer with infracost analysis requests

### Documentation → documentation
- Any `.md` file updates
- `README.md`, `CLAUDE.md`, `DEPLOYMENT.md`
- Documentation in `docs/` directories

## Agent Selection Decision Tree

When analyzing a request, consider:

1. **Primary indicators**:
   - File paths and layer names
   - Keywords in titles, descriptions, comments
   - Type of operation requested

2. **Context clues**:
   - Security-related: IAM, KMS, secrets, compliance → `security-compliance`
   - Cost-related: billing, infracost, optimization → `cost-optimization`
   - Infrastructure: terraform files, layer operations → `terraform-layer`
   - New functionality: features, enhancements → `feature-implementation`
   - Problems: bugs, errors, fixes → `issue-fix`
   - Writing: documentation, guides → `documentation`
   - Updates: dependencies, versions → `dependency-update`

3. **Fallback strategy**:
   - If uncertain or multiple indicators: Use `terraform-layer` (general infrastructure)
   - If clearly specialized: Use the most specific agent
   - If mixed context: Choose the agent for the primary concern

## Intelligent Routing Examples

### Example 1: Security Layer
**Context**: Working on `apps-devstg/us-east-1/secrets-manager/main.tf`
**Analysis**: Path contains "secrets-manager" → security-related layer
**Decision**: Use `security-compliance` agent
**Reasoning**: Secrets management requires security expertise, KMS knowledge, IAM policies

### Example 2: Cost Analysis
**Context**: PR with infracost changes, cost optimization discussion
**Analysis**: Keywords "infracost", "cost", "optimization"
**Decision**: Use `cost-optimization` agent
**Reasoning**: Specialized in infracost analysis, cost monitoring, resource optimization

### Example 3: Infrastructure Layer
**Context**: Adding new EKS cluster in `shared/us-east-1/k8s-eks/`
**Analysis**: Infrastructure layer with .tf files, k8s-related
**Decision**: Use `terraform-layer` agent
**Reasoning**: General infrastructure operations, OpenTofu expertise needed

### Example 4: Mixed Context
**Context**: Security layer with cost optimization request
**Analysis**: Both security and cost keywords present
**Decision**: Use `security-compliance` agent (primary layer type wins)
**Reasoning**: Security expertise needed for the layer, can consider cost aspects

## Usage Instructions

When Claude encounters a request:

1. **Analyze the context**: Look at file paths, keywords, request type
2. **Identify the primary domain**: Security, cost, infrastructure, documentation, etc.
3. **Select the most appropriate agent** using the guide above
4. **Use the Task tool** with the chosen `subagent_type`
5. **Provide clear reasoning** for the agent selection

This approach leverages Claude's natural language understanding for intelligent, flexible routing without rigid programmatic rules.