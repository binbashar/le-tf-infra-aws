# Credentials Inventory

All secrets referenced by Claude Code GitHub workflows in this repository.

## Secret Inventory

| Secret | Used By | Risk | Purpose |
|--------|---------|------|---------|
| `CLAUDE_CODE_OAUTH_TOKEN` | claude.yml, claude-code-review.yml, terraform-plan-review.yml | Medium | OAuth token for Claude Code Action — authenticates AI analysis |
| `AWS_ACCESS_KEY_ID` | terraform-plan-review.yml | **High** | Static IAM access key for DeployMaster role — used in plan/apply |
| `AWS_SECRET_ACCESS_KEY` | terraform-plan-review.yml | **High** | Static IAM secret key paired with access key |
| `AWS_MANAGEMENT_ACCOUNT_ID` | terraform-plan-review.yml | Low | Management account ID for assume-role ARN construction |
| `AWS_SECURITY_ACCOUNT_ID` | terraform-plan-review.yml | Low | Security account ID for assume-role ARN construction |
| `AWS_SHARED_ACCOUNT_ID` | terraform-plan-review.yml | Low | Shared account ID for assume-role ARN construction |
| `AWS_NETWORK_ACCOUNT_ID` | terraform-plan-review.yml | Low | Network account ID for assume-role ARN construction |
| `AWS_DEVSTG_ACCOUNT_ID` | terraform-plan-review.yml | Low | DevStg account ID for assume-role ARN construction |
| `AWS_PRD_ACCOUNT_ID` | terraform-plan-review.yml | Low | Production account ID for assume-role ARN construction |
| `AWS_DATA_SCIENCE_ACCOUNT_ID` | terraform-plan-review.yml | Low | Data Science account ID for assume-role ARN construction |
| `GITHUB_TOKEN` | All workflows | Low | Auto-rotated per workflow run — scoped to repo permissions |

## Risk Assessment

### High Risk: Static IAM Keys (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)

**Concern**: Long-lived static credentials stored as GitHub secrets. If leaked, they provide access to all AWS accounts via DeployMaster role assumption.

**Current mitigations**:
- GitHub encrypts secrets at rest
- Secrets are masked in logs
- Authorization gates restrict who can trigger workflows
- Only plan/apply jobs use these credentials

**Recommended migration**: Replace with GitHub Actions OIDC federation (see below).

### Medium Risk: Claude Code OAuth Token

**Concern**: Grants Claude Code API access. If leaked, could be used to run Claude Code actions outside this repo.

**Current mitigations**:
- Authorization gates prevent unauthorized users from triggering Claude workflows
- Token is scoped to Claude Code Action usage

### Low Risk: Account IDs and GITHUB_TOKEN

Account IDs are not secret by themselves — they are used only for ARN construction. `GITHUB_TOKEN` is auto-rotated per workflow run.

## OIDC Migration Path (Recommended)

Replace static IAM keys with GitHub Actions OIDC federation for zero-credential CI/CD:

### Steps

1. **Create IAM OIDC provider** in management account:
   - Provider URL: `token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

2. **Create IAM role** with trust policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": {
         "Federated": "arn:aws:iam::MANAGEMENT_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
       },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": {
           "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
         },
         "StringLike": {
           "token.actions.githubusercontent.com:sub": "repo:binbashar/le-tf-infra-aws:*"
         }
       }
     }]
   }
   ```

3. **Update workflows** to use `aws-actions/configure-aws-credentials@v4`:
   ```yaml
   - uses: aws-actions/configure-aws-credentials@v4
     with:
       role-to-assume: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
       aws-region: us-east-1
   ```

4. **Remove static secrets**: Delete `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` from repository settings.

### Benefits
- No static credentials to leak
- Temporary credentials auto-expire
- Fine-grained trust policy (repo + branch scoping)
- `id-token: write` permission becomes justified

### Implementation
This requires Terraform changes in the management account and should be done in a separate PR.
