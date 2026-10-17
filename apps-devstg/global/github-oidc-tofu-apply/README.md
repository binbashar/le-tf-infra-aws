# GitHub OIDC identity for `tofu-apply` (apps-devstg)

This layer creates the OpenTofu **apply** role for apps-devstg: the write identity for the planned
apply-before-merge flow (`/tofu apply` on a PR). Unlike
[`github-oidc-tofu-plan`](../github-oidc-tofu-plan/), this role can change infrastructure, so its
scope is kept to the allowlisted layers and it is fenced by a permissions boundary.

It does not create the GitHub OIDC provider. The account allows one provider per issuer, and the
plan layer owns it; this layer reads it with a data source.

## Trust boundary

The role can be assumed only by a token that matches **all** of:

| Claim | Value |
| --- | --- |
| `aud` | `sts.amazonaws.com` |
| `sub`, `environment` | `repo:binbashar/le-tf-infra-aws:environment:tofu-apply` |
| `repository_id`, `repository_owner_id` | The repository's and the organization's immutable IDs |
| `ref` | `refs/heads/master` |
| `job_workflow_ref` | `binbashar/le-tf-infra-aws/.github/workflows/tofu-apply.yml@refs/heads/master` |

`/tofu apply` runs from an `issue_comment` event. GitHub always runs those from the default
branch's copy of the workflow, so `ref` is `master` even though the code being applied comes from
the PR. The `job_workflow_ref` condition means no other workflow can use the role, even one that
targets the `tofu-apply` environment. If AWS does not evaluate that claim, the condition fails
closed and the first supervised apply will show it.

Configure the `tofu-apply` environment with these settings:

- the `leverage-ref-architecture-aws-admin` team as the only required reviewer;
- **Prevent self-review**;
- no administrator bypass;
- `master` as the only deployment branch.

## Permissions

The role's policy is the union of the layers in `local.apply_targets`:

- **Backend, shared, in `policy.tf`:** read and write of each target's state object, its exact
  DynamoDB lock keys, and an explicit deny on deleting state objects. The bucket is versioned, so
  every apply leaves the previous state recoverable.
- **Provider calls, per layer, in `apply-target-<layer>.tf`:** today only
  `apps-devstg/global/cli-test-layer`. That means create, update, read, and delete of its
  `LeverageTest` role and `leverage_test` policy, with `AttachRolePolicy` and `DetachRolePolicy`
  limited to that one policy ARN. The layer has no `PutRolePolicy`, no permissions-boundary
  changes, and no `iam:PassRole`.

The workflow will narrow each job to its own layer with an inline session policy, as the plan
workflow does.

**Write access to an IAM-managing layer is close to admin for that layer's principals.** An
approved PR can change `leverage_test`'s document or `LeverageTest`'s trust. The controls are
the `tofu-apply` approval by the admin team and the digest check, which ensures the reviewed plan
is the one applied. Record the same risk whenever another IAM layer is onboarded.

## Permissions boundary

`GitHubActionsOpenTofuApplyBoundary` allows everything the role's own policy allows, then denies:

- any IAM action on `role/GitHubActionsOpenTofu*` and `policy/GitHubActionsOpenTofu*`, which
  covers this role, its policy, the boundary itself, and the plan and Bedrock identities;
- any IAM action on the GitHub OIDC provider;
- deleting a permissions boundary from any role or user.

These denies hold even if a future target grants broad IAM rights.

IAM Access Analyzer reports nothing for the permissions policy. For the boundary it reports
`CREATE_SLR_WITH_STAR_IN_ACTION_AND_RESOURCE` and `PASS_ROLE_WITH_STAR_IN_ACTION_AND_RESOURCE`.
Both are expected: a boundary only caps permissions, and the effective permissions are its
intersection with the role's policy, which grants neither action. For the trust policy it reports
the usual `CONFIRM_AUDIENCE_CLAIM_TYPE` suggestion (see the plan layer's README).

## Adding a layer

1. Add the layer to `local.apply_targets` with its backend key.
2. Add `apply-target-<layer>.tf` with the provider calls for create, update, read, and delete,
   scoped to the layer's resource ARNs. Prefer conditions that pin what can be attached or passed.
3. Plan and review, apply as a maintainer, and run a supervised apply on a throwaway change.

## Deployment

Apply this layer only after the plan layer exists (it reads the OIDC provider). From this layer:

```bash
leverage tofu init
leverage tofu plan
```

Review the trust conditions, both policies, and the boundary. A maintainer applies the layer
locally; no workflow can apply it. After the apply, create the `tofu-apply` environment as
described above. Configuring the role for the workflow comes with the apply workflow itself.
