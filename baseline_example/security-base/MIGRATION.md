### Migration guide: adopting the new security-base framework version

This guide explains how to migrate existing, already-provisioned resources into Terraform state using import blocks, and how to safely apply the new module without recreating resources.

---

## Scope
- **Target**: `baseline/security-base` stack
- **Goal**: Import pre-existing account-level security resources (e.g., EBS encryption by default, S3 account public access block) into Terraform using `imports.tf` and then apply the new configuration without drift.

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

You can use `imports.tf.example` in this folder as a starting template. Copy it to `imports.tf` and replace placeholders with the correct resource addresses and IDs for each account/region.

Example template:

```hcl
import {
  to = aws_ebs_encryption_by_default.main["apps-devstg-us-east-1"]
  id = "123456789012" # AWS Account ID for the target account
}
```

Your repository already includes a curated `imports.tf` aligned with `plan.txt`. For reference, it follows this pattern:

```8:18:baseline/security-base/imports.tf
import {
  to = aws_ebs_encryption_by_default.main["apps-devstg-us-east-1"]
  id = "523857393444"
}
```

Repeat for each account/region and for each resource type (e.g., `aws_s3_account_public_access_block`). Ensure the `id` value matches the provider's expected import ID (for these account-level resources, it is the AWS Account ID).

## Commands
Run the following from `baseline/security-base`.

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
