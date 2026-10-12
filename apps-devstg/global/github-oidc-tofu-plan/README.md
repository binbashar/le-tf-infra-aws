# GitHub OIDC identity for `tofu-plan` (apps-devstg)

This layer owns the account-wide GitHub Actions OIDC provider in `apps-devstg` and dedicated
OpenTofu automation identities. It creates two independent roles: the plan role and an invoke-only
Bedrock explanation role. Neither is a deployment role. The management account has a matching
layer, [`management/global/github-oidc-tofu-plan`](../../../management/global/github-oidc-tofu-plan/),
with a plan role only.

## Trust boundary

Each role can be assumed only when GitHub issues a token for its own protected
environment:

| Role | Environment |
| --- | --- |
| Plan | `tofu-plan` |
| Bedrock explanation | `tofu-plan-bedrock` |

Every trust policy also requires the repository's immutable ID, the `binbashar`
organization ID, a pull-request merge ref or the `master` branch, and the
`sts.amazonaws.com` audience. Configure each environment with a reviewer other
than the run initiator, **Prevent self-review**, and no administrator bypass.

## Permission boundary

The plan role's policy is the union of the layers in `local.plan_targets`: each entry's S3 state
object and exact DynamoDB lock keys (shared statements in `policy.tf`) plus the provider reads in
its own `plan-target-<layer>.tf`. Today that is only `apps-devstg/global/cli-test-layer`, which
needs its target role and managed policy. The workflow narrows every job to its own layer's state
and lock with an inline session policy. The role has no IAM mutation,
secret-read, KMS-decrypt, `iam:PassRole`, or general resource-read permission. State object writes
and deletes are explicitly denied.

The Bedrock role can invoke only the configured system inference profile and its verified
destination foundation models, plus the exact regional Amazon Nova Lite fallback. A condition
prevents direct model invocation outside that profile or the one explicitly named fallback; it has
no state, IAM-read, or infrastructure permission. The workflow sends it only the sanitized plan
projection.

The workflow still defaults to the system inference profile. While the Anthropic account agreement
is pending, a maintainer may set `BEDROCK_MODEL_ID=amazon.nova-lite-v1:0` only after applying this
layer's reviewed policy update. The analyzer recognizes only that exact Nova model ID and uses a
forced, schema-bound tool call for its output. Any other unpermitted model ID fails closed.

The DynamoDB write operations are only for the state lock. If a plan requires any other write,
state access, or broad read, stop and review the provider operation rather than broadening the
policy generically.

## Policy validation

IAM Access Analyzer reports no findings for the permissions policy. It reports two expected
findings for the trust policy:

- `CONFIRM_AUDIENCE_CLAIM_TYPE`: `sts.amazonaws.com` is intentional and is the audience required
  by GitHub's official AWS OIDC integration.
- `SPECIFIC_GITHUB_REPO_AND_BRANCH_RECOMMENDED`: an environment-based GitHub subject contains the
  repository and environment rather than a branch. The separate `ref` condition restricts tokens
  to `master` or pull-request merge refs, and the protected environment supplies the per-commit
  reviewer boundary.

See GitHub's
[AWS OIDC guide](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws)
and AWS's
[GitHub OIDC trust guidance](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html).

## Deployment

This layer was renamed from `github-actions-opentofu` on 2026-10-11; its state moved from
`apps-devstg/github-actions-opentofu/terraform.tfstate` to the key in `config.tf` with
`leverage tofu init -migrate-state`.

Before the first plan, confirm with a read-only AWS query that this account still has no provider
for `https://token.actions.githubusercontent.com`. An account can have only one provider for that
issuer; if one appears, import or reference its established owner instead of applying a duplicate.

From this exact layer, use the normal maintainer-operated flow:

```bash
leverage tofu init
leverage tofu plan -no-color -detailed-exitcode
```

Review the provider, trust conditions, role policy, backend, and absence of unrelated changes.
Applying this bootstrap is a maintainer decision; the plan workflow has no apply path.

After a reviewed apply, add the plan role ARN and account ID under `apps-devstg` in the
`TOFU_PLAN_ROLES` repository variable.
Configure the Bedrock role as `AWS_TOFU_PLAN_BEDROCK_ROLE_ARN` and
`AWS_TOFU_PLAN_BEDROCK_ACCOUNT_ID`. Keep `TOFU_PLAN_LIVE=false` and
`TOFU_PLAN_LLM=false` outside the supervised windows described in
[`docs/ai-sdlc/tofu-plan-rollout.md`](../../../docs/ai-sdlc/tofu-plan-rollout.md).
