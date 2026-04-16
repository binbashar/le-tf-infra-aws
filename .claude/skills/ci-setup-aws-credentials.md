---
description: "Deterministic AWS credentials setup for CI workflows"
allowed-tools: ["Bash"]
---

# AWS Credentials Setup for CI

Deterministic setup — no AI reasoning needed. Use this as a reference for AWS credential configuration in GitHub Actions workflows.

## Account Structure

| Account | Secret Suffix | Profile |
|---------|--------------|---------|
| apps-devstg | `DEVSTG` | `bb-apps-devstg-devops` |
| apps-prd | `PRD` | `bb-apps-prd-devops` |
| network | `NETWORK` | `bb-network-devops` |
| security | `SECURITY` | `bb-security-devops` |
| shared | `SHARED` | `bb-shared-devops` |
| management | `MANAGEMENT` | `bb-management-devops` |
| data-science | `DATA_SCIENCE` | `bb-data-science-devops` |

## Required Secrets

- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — DeployMaster IAM user credentials
- `AWS_{SUFFIX}_ACCOUNT_ID` — One per account (7 total)
- `CLAUDE_CODE_OAUTH_TOKEN` — For AI-powered analysis steps

## Workflow Steps

1. Use `.github/actions/determine-account` to map layer path -> account/secret/profile
2. Use `.github/actions/leverage-aws-credentials` to write AWS config files
3. Set `AWS_PROFILE` env var to the profile from step 1
4. Use `.github/actions/leverage-configure-ref-arch` to create common.tfvars and build.env

## OIDC Migration (Future)

Replace static keys with `aws-actions/configure-aws-credentials@v4` using `role-to-assume`. See `.github/docs/credentials-inventory.md` for the full migration plan.
