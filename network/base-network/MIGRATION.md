### Migration guide: adopting the new network-base framework version

This guide explains how to migrate existing, already-provisioned VPC resources into Terraform state using import blocks, and how to safely apply the new module without recreating resources.

---

## Scope
- **Target**: `network/base-network` stack
- **Goal**: Import pre-existing VPC resources (VPC, Subnets, Internet Gateway, Route Tables, etc.) into Terraform using `imports.tf` and then apply the new configuration without drift.

## Prerequisites
- Terraform >= 1.5 (supports `import {}` blocks in configuration)
- Valid AWS credentials for each target account (via profiles or SSO)
- The existing `plan.txt` produced from an initial dry-run of the new framework (shows what Terraform would create)

## High-level steps
1) Generate an initial plan to discover resources Terraform intends to create.
2) From that plan, compose `imports.tf` with `import { to, id }` blocks mapping to the real, existing resources.
3) Run `terraform plan` again; verify that resources are now recognized as "to import" rather than "to create".
4) Execute the import-aware apply to write resources into state without changes.
5) Remove or keep `imports.tf` based on your team policy (see "Post-import cleanup").

## Compose `imports.tf`
`imports.tf` should contain one `import {}` per resource instance, where:
- `to` is the full resource address in the current configuration (including keys for for_each maps)
- `id` is the remote resource identifier required by the provider

Your repository already includes a curated `imports.tf` aligned with `devstg` environment. For reference, it follows this pattern:

```hcl
import {
  to = module.vpc.aws_vpc.this[0]
  id = "vpc-072f329fed6757e95" # Replace with actual VPC ID
}
```

**Action Required**:
- Review `imports.tf` and ensure the `id` fields match the actual resource IDs in your AWS account.
- Use the AWS CLI commands provided in the comments of `imports.tf` to verify IDs.
- If migrating other environments (e.g., `prd`), you will need to create a similar `imports.tf` with the correct IDs for that environment.

## Commands
Run the following from `network/base-network`.

```bash
# 1) Initialize/upgrade providers
leverage tf init --skip-validation

# 2) Validate configuration
leverage tf validate

# 3) Preview the import actions (should show "to import")
leverage tf plan 

# 4) Apply the imports (records resources in state, no changes to infra)
leverage tf apply 
```

Notes:
- If you prefer, you can skip the `-out=tfplan` and run `leverage tf apply` directly after reviewing the plan.
- If any resource still shows as "to create", either its `import {}` block is missing or the `id` is incorrect.

## Verifying state
- After apply, run `leverage tf state list` and confirm addresses for imported resources are present.
- Optionally run `leverage tf plan` again; it should be a no-op (or only show expected outputs/locals changes).

## Post-import cleanup
- Teams commonly keep `imports.tf` under version control for auditability and future re-imports.
- Alternatively, once state is correct and plans are clean, you may remove specific `import {}` blocks to reduce noise. If you do so, commit that change only after confirming the plan remains a no-op.
