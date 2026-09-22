# GitHub Actions OpenTofu identity

This layer owns the account-wide GitHub Actions OIDC provider in `apps-devstg` and dedicated
OpenTofu automation identities. It creates three independent roles: the pilot-layer plan role, a
separate role for the supervised no-change verification, and an invoke-only Bedrock explanation
role. None is a deployment role.

## Trust boundary

The role can be assumed only when GitHub issues a token for:

- repository `binbashar/le-tf-infra-aws`;
- protected environment `tofu-plan-poc`;
- the repository's immutable ID and the `binbashar` organization ID;
- a pull-request merge ref or the `master` branch; and
- audience `sts.amazonaws.com`.

The GitHub environment requires a reviewer other than the run initiator and disallows
administrator bypass. Keep those controls in place while this role exists.

## Permission boundary

The pilot plan role can read only its configured target layer's S3 state object, acquire and
release its exact DynamoDB lock, and inspect the target role and managed policy. The no-change role
has a separate, similarly bounded policy for this identity layer. Neither role has IAM mutation,
secret-read, KMS-decrypt, `iam:PassRole`, or general resource-read permission. State object writes
and deletes are explicitly denied.

The Bedrock role can invoke only the configured system inference profile and its verified
destination foundation models. A condition prevents direct model invocation outside that profile;
it has no state, IAM-read, or infrastructure permission. The workflow sends it only the sanitized
plan projection.

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

Before the first plan, confirm with a read-only AWS query that this account still has no provider
for `https://token.actions.githubusercontent.com`. An account can have only one provider for that
issuer; if one appears, import or reference its established owner instead of applying a duplicate.

From this exact layer, use the normal maintainer-operated flow:

```bash
leverage tofu init
leverage tofu plan -no-color -detailed-exitcode
```

Review the provider, trust conditions, role policy, backend, and absence of unrelated changes.
Applying this bootstrap is a maintainer decision; the POC workflow has no apply path.

After a reviewed apply, configure the pilot plan role ARN and account ID as
`AWS_TOFU_PLAN_ROLE_ARN` and `AWS_TOFU_PLAN_ACCOUNT_ID` repository variables. For the no-change
verification only, temporarily point those variables at the no-change role and set
`TOFU_PLAN_POC_LAYER=apps-devstg/global/github-actions-opentofu`; restore both afterward. Configure
the Bedrock role as `AWS_TOFU_PLAN_BEDROCK_ROLE_ARN` and
`AWS_TOFU_PLAN_BEDROCK_ACCOUNT_ID`. Keep `TOFU_PLAN_POC_LIVE=false` and
`TOFU_PLAN_POC_LLM=false` until their respective supervised windows described in
`docs/ai-sdlc/tofu-plan-poc-rollout.md`.
