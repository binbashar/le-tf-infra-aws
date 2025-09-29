# Agentic Routing Test Scenarios

This document demonstrates how the intelligent agent routing system works with real-world examples from the Binbash Leverage Reference Architecture.

## Test Scenario 1: Security Layer Work

### Context
- **Files changed**: `apps-devstg/us-east-1/secrets-manager/main.tf`, `apps-devstg/us-east-1/secrets-manager/variables.tf`
- **PR title**: "Add KMS encryption for application secrets"
- **Description**: "Implementing KMS encryption for secrets in the development environment with proper IAM policies"

### Expected Routing Decision
```
Context Analysis:
- File path contains "secrets-manager" → Security layer
- Keywords: "KMS encryption", "secrets", "IAM policies"
- Layer type: Security-related infrastructure

Selected Agent: security-compliance
Reasoning: This work involves secrets management, KMS encryption, and IAM policies - all core areas of the security-compliance agent's expertise.
```

### Agent Task Delegation
```
Task tool with subagent_type: "security-compliance"
prompt: "Please review this pull request for KMS encryption implementation in the secrets-manager layer..."
```

## Test Scenario 2: Cost Optimization Request

### Context
- **Files changed**: `management/us-east-1/notifications/cost-alerts.tf`
- **Issue title**: "Infracost analysis shows high cost in RDS instances"
- **Comment**: "@claude please analyze the cost impact and suggest optimizations for our database layers"

### Expected Routing Decision
```
Context Analysis:
- File path contains "notifications" with cost-related content
- Keywords: "Infracost analysis", "high cost", "cost impact", "optimizations"
- Request type: Cost analysis and optimization

Selected Agent: cost-optimization
Reasoning: This is clearly a cost analysis request involving infracost data and optimization recommendations.
```

### Agent Task Delegation
```
Task tool with subagent_type: "cost-optimization"
prompt: "Please analyze the cost impact and provide optimization recommendations for the database layers..."
```

## Test Scenario 3: General Infrastructure Layer

### Context
- **Files changed**: `shared/us-east-1/k8s-eks/cluster.tf`, `shared/us-east-1/k8s-eks/node-groups.tf`
- **PR title**: "Update EKS cluster to version 1.28"
- **Description**: "Upgrading EKS cluster and updating node group configurations"

### Expected Routing Decision
```
Context Analysis:
- File path contains "k8s-eks" → Infrastructure layer
- Keywords: "EKS cluster", "node group configurations"
- Layer type: Kubernetes infrastructure

Selected Agent: terraform-layer
Reasoning: This is general infrastructure work involving EKS cluster operations and terraform configurations.
```

### Agent Task Delegation
```
Task tool with subagent_type: "terraform-layer"
prompt: "Please review this EKS cluster upgrade with your infrastructure expertise..."
```

## Test Scenario 4: Documentation Update

### Context
- **Files changed**: `README.md`, `docs/deployment-guide.md`, `CLAUDE.md`
- **PR title**: "Update documentation for new deployment process"
- **Description**: "Adding new sections for deployment workflows and updating examples"

### Expected Routing Decision
```
Context Analysis:
- File paths: All .md files
- Keywords: "documentation", "deployment process", "workflows", "examples"
- Change type: Documentation updates

Selected Agent: documentation
Reasoning: All changes are to documentation files with clear documentation-focused keywords.
```

### Agent Task Delegation
```
Task tool with subagent_type: "documentation"
prompt: "Please review these documentation updates for the deployment process..."
```

## Test Scenario 5: Bug Fix

### Context
- **Files changed**: `apps-devstg/us-east-1/databases-aurora/aurora.tf`
- **Issue title**: "Aurora cluster fails to start due to parameter group mismatch"
- **Comment**: "@claude the database cluster is failing to start, can you help fix this?"

### Expected Routing Decision
```
Context Analysis:
- Keywords: "fails to start", "failing", "fix this"
- Issue type: Problem resolution
- Context: Database infrastructure problem

Selected Agent: issue-fix
Reasoning: This is clearly a bug fix request with error resolution needed, despite being in a database layer.
```

### Agent Task Delegation
```
Task tool with subagent_type: "issue-fix"
prompt: "Please help troubleshoot and fix the Aurora cluster startup issue..."
```

## Test Scenario 6: Mixed Context (Security + Infrastructure)

### Context
- **Files changed**: `security/us-east-1/security-base/main.tf`, `security/us-east-1/security-base/iam.tf`
- **PR title**: "Implement SecurityHub and GuardDuty with proper IAM roles"
- **Description**: "Setting up centralized security monitoring with IAM roles and policies"

### Expected Routing Decision
```
Context Analysis:
- File path contains "security-base" → Security layer
- Keywords: "SecurityHub", "GuardDuty", "IAM roles", "security monitoring"
- Primary focus: Security services and compliance

Selected Agent: security-compliance
Reasoning: Despite involving infrastructure, the primary focus is on security services (SecurityHub, GuardDuty) and IAM - core security-compliance expertise.
```

### Agent Task Delegation
```
Task tool with subagent_type: "security-compliance"
prompt: "Please review this SecurityHub and GuardDuty implementation with your security expertise..."
```

## Test Scenario 7: Dependency Update

### Context
- **Files changed**: `apps-devstg/us-east-1/k8s-eks/.terraform.lock.hcl`, `apps-devstg/us-east-1/k8s-eks/versions.tf`
- **PR title**: "Update AWS provider to version 5.100"
- **Comment**: "Renovate PR: Updates AWS provider for security patches"

### Expected Routing Decision
```
Context Analysis:
- File paths: .terraform.lock.hcl, versions.tf
- Keywords: "Update", "provider version", "Renovate", "security patches"
- Change type: Dependency/version update

Selected Agent: dependency-update
Reasoning: This is a clear dependency update with version changes and security patches.
```

### Agent Task Delegation
```
Task tool with subagent_type: "dependency-update"
prompt: "Please review this AWS provider version update for compatibility and security..."
```

## Testing the System

To test this agentic routing system:

1. **Create a test PR** with files in a specific layer (e.g., secrets-manager)
2. **Add a comment** mentioning @claude with a specific request
3. **Observe Claude's reasoning** in the workflow output
4. **Verify agent selection** matches the expected scenario
5. **Check specialized response** from the delegated agent

## Validation Criteria

The agentic routing system should:
- ✅ Correctly analyze file paths and layer types
- ✅ Identify relevant keywords in titles and descriptions
- ✅ Select the most appropriate specialized agent
- ✅ Provide clear reasoning for the selection
- ✅ Delegate to the Task tool with proper subagent_type
- ✅ Handle mixed contexts intelligently
- ✅ Fall back to terraform-layer for unclear cases

This natural language approach provides much more flexibility than programmatic if/else routing while maintaining intelligent specialization.