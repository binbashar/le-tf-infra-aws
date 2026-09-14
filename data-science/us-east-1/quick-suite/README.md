# Reference Architecture: Amazon Quick (QuickSight)

## Overview

This layer subscribes the **data-science** account to **Amazon Quick** (the product formerly
called Amazon QuickSight) on the **Enterprise** edition, authenticating against the IAM
Identity Center **organization instance** that lives in the **management** account and is
managed by `management/global/sso`.

| File | Contents |
|---|---|
| `config.tf` | Local provider, the `aws.management` alias, and the backend |
| `sso-groups.tf` | Identity Center instance + group lookups, read through `aws.management` |
| `locals.tf` | Quick role → Identity Center group map |
| `quick-suite.tf` | `aws_quicksight_account_subscription` + `aws_quicksight_role_membership` |
| `variables.tf` | Account name, edition, notification email |

### Why identity and BI live in different accounts

AWS supports this split directly, and documents it as the recommended shape: group creation
happens "within the management account of your AWS Organizations or a delegated administrator
account", while Quick sign-up happens "within the target Data Collection AWS account, which
should be part of the same AWS Organizations as IAM Identity Center". Two requirements follow,
both satisfied here:

- the subscribing account is in the same organization as the Identity Center instance;
- **Quick runs in the same region as the instance** — `us-east-1` for both.

Keeping Quick out of the management account leaves the payer account to organizations, billing
and identity, and puts BI next to the data lake and Bedrock workloads it actually reads.

The one consequence is that this account cannot read the organization's identity store with its
own credentials (`identitystore:GetGroupId` returns `AccessDenied`), so `sso-groups.tf` reads it
through the `aws.management` provider alias — the same pattern
`network/us-east-1/client-vpn/sso-groups.tf` already uses.

## How access works

Quick reads IAM Identity Center group membership directly — there is no SAML federation and no
permission set involved. Each group maps to exactly one Quick role:

| Identity Center group | Quick role | Price |
|---|---|---|
| `QuickAdmin` | `ADMIN` | USD 24 / user / month |
| `QuickAuthor` | `AUTHOR` | USD 24 / user / month |
| `QuickReader` | `READER` | USD 3 / user / month |

The groups are declared in `management/global/sso/locals.tf` next to `kiropro`, and like it
they are **absent from `account_assignments.tf`** — they carry no permission set and grant no
AWS access. Membership buys a Quick seat and nothing else.

### Granting or revoking a seat

A code change only, in **one** file:

1. Add or remove `"quickadmin"` / `"quickauthor"` / `"quickreader"` in the user's `groups`
   list in `management/global/sso/locals.tf`.
2. Apply the `sso` layer. Nothing in *this* layer changes.
3. Each member is billed at the rate above.

`QuickReader` is intentionally created empty. An empty group costs nothing and is already bound
to its role, so the first reader is a one-line edit rather than a layer change.

## Why the subscription and the mappings are split

`aws_quicksight_account_subscription` marks **every** argument `ForceNew` and implements **no
Update** — it is create/read/delete only. Editing `admin_group`, `author_group` or
`reader_group` in place therefore plans a *destroy and re-create of the whole subscription*,
taking every dashboard, analysis and dataset with it.

So the layer sets only what signup demands — `admin_group`, since `CreateAccountSubscription`
requires at least one admin group — and manages everything else through
`aws_quicksight_role_membership`, which is freely created and destroyed. Adding a mapping never
re-plans the subscription.

`prevent_destroy = true` backs this up: a plan that would replace the subscription fails hard
instead of quietly tearing it down.

## Deployment

### Prerequisite: retire the legacy subscription

This account already carried a QuickSight subscription (`binbash-data-science`) on the legacy
`IDENTITY_POOL` authentication method. AWS is explicit that **"it is not possible to enable IAM
Identity Center support for an existing Quick Sight installation"**, so it has to be deleted
before this layer is applied. Its contents were AWS's auto-generated sample artifacts only —
four analyses, four datasets, four data sources, zero dashboards, zero folders — and its single
`ADMIN` seat was the USD 24/month charge raised as item 2 of
`docs/finops/finops-optimization-2026-09-13-1010.md`.

Termination protection is on by default and blocks deletion, so it is a two-call teardown:

```bash
aws quicksight update-account-settings \
  --aws-account-id <DATA_SCIENCE_ACCOUNT_ID> --default-namespace default \
  --no-termination-protection-enabled --profile bb-data-science-devops --region us-east-1

aws quicksight delete-account-subscription \
  --aws-account-id <DATA_SCIENCE_ACCOUNT_ID> --profile bb-data-science-devops --region us-east-1
```

Also clean up the abandoned half-signup in the management account — an Identity Center
application named `binbash` with provider `quicksight`, left behind by a console sign-up that
authorized the identity provider but never created a subscription
(`aws sso-admin delete-application --application-arn <ARN>`). No subscription was ever created
there, so the `binbash` account name is free.

### Execution role permissions

Signing up with Identity Center needs more than `quicksight:*`. `CreateAccountSubscription`
registers an Identity Center application on the caller's behalf, so AWS's documented policy for
[Enterprise edition with IAM Identity Center](https://docs.aws.amazon.com/quick/latest/userguide/iam-policy-examples.html)
also requires ten `sso:` application actions — `CreateApplication`, `DescribeInstance`,
`PutApplicationAuthenticationMethod`, `PutApplicationGrant` among them. The `DevOps` permission
set this layer runs under carried only `sso:ListInstances` and `sso:DescribeRegisteredRegions`,
so the apply would have failed after the group lookups succeeded.

The missing actions are added to `data.aws_iam_policy_document.devops` in
`management/global/sso/policies.tf` as part of the same change. That is a second reason the SSO
layer has to be applied first, and it means the operator's session must be **re-issued** after
that apply — an Identity Center session minted before the permission set changed still carries
the old policy.

### Apply

The groups must exist in Identity Center **before** this layer is applied, so this is a
two-step across layers — the same two-step the SSO README documents for name-resolved
principals:

```bash
cd management/global/sso
leverage tofu apply            # creates QuickAdmin / QuickAuthor / QuickReader

cd ../../../data-science/us-east-1/quick-suite
leverage tofu init
leverage tofu plan             # resolves the three groups, then plans the subscription
leverage tofu apply
```

Until the SSO layer is applied, `plan` here fails on the `data.aws_identitystore_group.quick`
lookup with `GROUP not found`. That is the guard doing its job, not a misconfiguration.

## Notes and constraints

- **The Identity Center choice is irreversible.** A live subscription cannot be moved to
  another access approach without cancelling it, and Quick
  [namespaces](https://docs.aws.amazon.com/quicksuite/latest/userguide/namespaces.html) are
  unavailable while it is in force.
- **Pro tiers are deliberately not configured.** `Admin Pro`, `Author Pro` and `Reader Pro`
  unlock generative BI, but add a **USD 250 per-account monthly infrastructure fee** once Pro
  Q&A features are switched on — more than the whole roster costs at current headcount. Adding
  one later means a new group in the SSO layer plus a line in `quick_role_memberships`, and an
  AWS provider bump to 6.x (`admin_pro_group` and siblings do not exist in 5.x).

## Retiring this layer

`prevent_destroy` and QuickSight's own termination protection are two separate guards, and
removing them deletes nothing on its own. While these resources stay declared, `leverage tofu
apply` keeps the subscription and **billing continues** — retiring it takes an explicit destroy.

1. Export, or accept losing, every dashboard, analysis and dataset in the account.
   `DeleteAccountSubscription` is irreversible.
2. Turn off QuickSight termination protection, or the delete call is refused:
   ```bash
   aws quicksight update-account-settings \
     --aws-account-id <DATA_SCIENCE_ACCOUNT_ID> --default-namespace default \
     --no-termination-protection-enabled --profile bb-data-science-devops --region us-east-1
   ```
3. Remove the `lifecycle { prevent_destroy = true }` block from `quick-suite.tf`; while it is
   present the destroy plan fails rather than running.
4. Produce a destroy plan, get it reviewed like any other change, and only then destroy:
   ```bash
   leverage tofu plan -destroy      # attach this to the PR for review
   leverage tofu destroy            # human-run, after approval
   ```

Deleting the resource blocks from the configuration and applying achieves the same result.
Either way the deletion has to be an explicit, reviewed act — never a side effect of dropping a
guard.

## References

- [Publishing as single sign-on (SSO) application](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/publishing-as-sso-application.html)
- [Granting Quick access through IAM Identity Center integration](https://docs.aws.amazon.com/prescriptive-guidance/latest/quick-suite-access-approach/iam-identity-center-integration.html)
- [Managing user access with IAM Identity Center](https://docs.aws.amazon.com/quick/latest/userguide/managing-user-access-idc.html)
- [Amazon QuickSight pricing](https://aws.amazon.com/quicksight/pricing/)
