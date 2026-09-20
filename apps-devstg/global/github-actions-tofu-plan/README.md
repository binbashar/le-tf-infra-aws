# GitHub Actions OpenTofu plan identity

This layer owns the account-wide GitHub Actions OIDC provider in `apps-devstg` and the dedicated
role used by the OpenTofu plan POC. It does not configure Bedrock access and it is not a deployment
role.

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

The role can read only the pilot layer's S3 state object, acquire and release its exact DynamoDB
lock, and inspect the `LeverageTest` role and `leverage_test` managed policy. It has no IAM mutation,
secret-read, KMS-decrypt, `iam:PassRole`, or general resource-read permission. State object writes
and deletes are explicitly denied.

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

After a reviewed apply, configure the role ARN and account ID as `AWS_TOFU_PLAN_ROLE_ARN` and
`AWS_TOFU_PLAN_ACCOUNT_ID` repository variables. Keep `TOFU_PLAN_POC_LIVE=false` until the
supervised run window described in `docs/ai-sdlc/tofu-plan-poc-rollout.md`.
