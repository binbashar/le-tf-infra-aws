# GitHub OIDC identity for `tofu-apply` (management)

This layer creates the OpenTofu **apply** role for management, used by `/tofu apply` on a PR
([`docs/tofu-plan-apply/tofu-apply.md`](../../../docs/tofu-plan-apply/tofu-apply.md)). It is the management copy
of [`apps-devstg/global/github-oidc-tofu-apply`](../../../apps-devstg/global/github-oidc-tofu-apply/):
the same trust, backend policy, and permissions boundary. Read that README for the trust claims
and the boundary.

It does not create the GitHub OIDC provider; [`github-oidc-tofu-plan`](../github-oidc-tofu-plan/)
owns it, and this layer reads it.

## Targets

| Layer | Provider calls | File |
| --- | --- | --- |
| `management/global/sso` | IAM Identity Center permission sets, account assignments, applications, and identity store users, groups, and memberships | `apply-target-sso.tf` |

The writes come from CloudTrail: the OpenTofu write events of the manual sso applies over 90 days
(2026-07-22 to 2026-10-13), plus their update and delete counterparts. The sso layer makes no IAM
writes; Identity Center creates the roles in each account itself.

## Risk: this role is close to organization admin

An approved PR can create a permission set with `AdministratorAccess` and assign it to anyone in
any account. Identity Center has no condition keys that limit which policy a permission set
gets, so least privilege cannot remove this. The controls are the same as for any apply:

- the PR approval and the `tofu-apply` approval, both by the `leverage-ref-architecture-aws-admin`
  team, with Prevent self-review;
- the digest check, which ensures the reviewed plan is the one applied.

### Anti-lockout guard

A mistaken apply could remove everyone's access to every account. The role cannot change the
**Administrator** permission set: its policies, its tags, its provisioning, or its assignments,
including new ones. Those changes stay manual.

Two consequences:

- A PR that touches Administrator fails at apply with `AccessDenied`. Changes that the same apply
  made earlier stay applied, and the lock is kept. Apply the rest manually with
  `leverage tofu apply`, then `/tofu unlock`. A change that touches every permission set, such as
  a tag in `local.tags`, always takes this path: apply it manually from the start.
- The guard does not cover users and group memberships. Removing the members of the group that
  holds Administrator is still possible, and is caught only in review.

Before relying on this guard, check that management can be reached without Identity Center: the
root user with MFA, or an IAM administrator.

## Deployment

Apply after `github-oidc-tofu-plan` (it reads the OIDC provider). From this layer:

```bash
leverage tofu init
leverage tofu plan
```

Review the trust conditions, both policies, and the boundary. A maintainer applies the layer
locally; no workflow can apply it. Then add the role to `TOFU_APPLY_ROLES` and the sso layer to
`TOFU_APPLY_LAYERS`.
