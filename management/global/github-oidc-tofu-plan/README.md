# GitHub OIDC identity for `tofu-plan` (management)

This layer owns the account-wide GitHub Actions OIDC provider in `management` and the read-only
role that the [`tofu-plan`](../../../docs/ai-sdlc/tofu-plan.md) workflow assumes to plan
management layers. It is not a deployment role. The apps-devstg counterpart,
[`apps-devstg/global/github-oidc-tofu-plan`](../../../apps-devstg/global/github-oidc-tofu-plan/),
also owns the Bedrock explanation role; this account has none.

## Trust boundary

The plan role can be assumed only with a GitHub token issued for the protected `tofu-plan`
environment. The trust policy also requires the repository's immutable ID, the `binbashar`
organization ID, a pull-request merge ref or the `master` branch, and the `sts.amazonaws.com`
audience. The environment requires a reviewer other than the run initiator, **Prevent
self-review**, and no administrator bypass.

## Permission boundary

The policy is the union of the layers in `local.plan_targets`:

| Layer | State key | Provider reads |
| --- | --- | --- |
| `management/global/sso` | `management/sso/terraform.tfstate` | [`plan-target-sso.tf`](plan-target-sso.tf): IAM Identity Center permission sets, account and application assignments, and identity-store users, groups, and memberships |

`policy.tf` grants each target's S3 state object, the bucket listing for exactly that key, and its
DynamoDB lock keys, and explicitly denies state writes and deletes. The workflow narrows every job
to its own layer's state and lock with an inline session policy.

The sso reads were derived from the CloudTrail events of a converged local plan (191 resources)
and are scoped to this organization's Identity Center instance and identity store. The role has
no write, `iam:PassRole`, secret-read, or KMS permission; the state bucket uses SSE-S3 and the lock
table uses AWS-owned encryption.

**Data exposure.** The role can read Identity Center user names and emails, and the sso state
contains them too. The workflow's sanitized report never persists values, but an approved PR's
code runs with this role, so environment approval is authorization to run that exact commit
against this data.

## Adding a layer

Follow [Layer onboarding](../../../docs/ai-sdlc/tofu-plan-rollout.md#layer-onboarding): add a
`plan_targets` entry and a `plan-target-<layer>.tf` with only the demonstrated reads.

## Deployment

The first apply creates this account's only GitHub OIDC provider; a read-only check on
2026-10-11 found none. From this exact layer:

```bash
leverage tofu init
leverage tofu plan -no-color -detailed-exitcode
leverage tofu apply
```

Applying is a maintainer decision; the plan workflow has no apply path. After the apply, add the
role ARN and account ID under `management` in the `TOFU_PLAN_ROLES` repository variable.
