# Reference Architecture: IAM Identity Center (AWS SSO)

## Overview
This layer manages the AWS IAM Identity Center organization instance that lives in the
**management** account (`us-east-1`):

| File | Contents |
|---|---|
| `locals.tf` | `users`, `groups` and the derived `users_groups_membership` map |
| `users_groups.tf` | `aws_identitystore_user` / `_group` / `_group_membership` resources |
| `permission_sets.tf` + `policies.tf` | Permission sets and their inline/managed policies |
| `account_assignments.tf` | Which group gets which permission set on which account |
| `client-vpn-application.tf` | SSO-integrated AWS Client VPN custom SAML application |

## Leverage Documentation

- **How it works**
    - [Identities](https://leverage.binbash.co/user-guide/ref-architecture-aws/features/identities/identities/)
- **User guide**
    1. [Configurations](https://leverage.binbash.com.ar/user-guide/ref-architecture-aws/configs/)
    2. [Workflow](https://leverage.binbash.com.ar/user-guide/ref-architecture-aws/workflow/)

---

## AWS Terraform Management

### Add/remove a user
1. Go to `management/global/sso`.
2. Edit `locals.tf` and add/remove the entry in the local `users` map. The map key is the
   short username, and `email` must be the user's primary email — Identity Center uses it as
   `user_name`, so the two have to match for sign-in to work.
3. List every group the user belongs to in their `groups` attribute. Each value must be a key
   of the local `groups` map.
4. Run the [Terraform workflow](https://leverage.binbash.com.ar/user-guide/ref-architecture-aws/workflow/) to apply the changes.

### Add/remove a group
1. Edit the local `groups` map in `locals.tf`.
2. If the new group is meant to grant AWS access, add its account assignments in
   `account_assignments.tf`.
3. **Two-step apply**: the `account-assignments` module looks the principal up by name, so the
   group must exist *before* the permission set that references it. Apply the group first, then
   the assignment (same when renaming or removing a referenced group).

### Kiro subscriptions (Pro — USD 20 / user / month)

Kiro seats are **not** provisionable with OpenTofu. As of 2026-09, subscription assignment is a
console-only operation:

- the AWS provider has no `q`/`kiro` service (only `qbusiness`, `qldb`, `quicksight`), and there
  is no `awscc`/CloudFormation resource type either;
- no `kiro` / `qdeveloper` / `user-subscriptions` client exists in the published AWS SDK models,
  so there is no `aws` CLI verb and therefore no `local-exec` fallback;
- the `q:CreateAssignment` / `q:UpdateAssignment` IAM actions exist but are console-internal.

What *is* managed here is the **seat roster**. Kiro subscribes an IAM Identity Center group as a
unit, so the `kiropro` group (display name `KiroPro`) carries the seats:

- it is deliberately **absent from `account_assignments.tf`**, so it is bound to no permission
  set and grants no AWS access — it only exists to hold Kiro seats;
- one group per tier. If a Pro+ / Power seat is ever needed, add a sibling group (e.g.
  `kiroproplus`) rather than mixing tiers in one group.

**One-time console step** (after the group is applied): Amazon Q Developer console → **Kiro** →
**Access management** → **Groups** tab → **Add group**. The *Assign groups* dialog stays empty
until you type, so search for `KiroPro`, select it and choose **Done**.

That dialog has no tier selector — the tier comes from the **Kiro profile plan**, managed with the
**Change plan** / **Deactivate plan** buttons on the same page, so confirm the profile sits on
**Kiro Pro** (USD 20/user/month). Once assigned, the Groups tab lists the group as `Subscribed`
with its plan and user count, and the `AWSServiceRoleForUserSubscriptions` service-linked role
keeps the subscriptions in sync as the group membership changes.

> Group-based subscriptions are not immediate: the console warns of a delay of **up to 24 hours**
> before members can actually access the subscription.

**Granting or revoking a seat afterwards** is a code change only:
1. Add or remove `"kiropro"` in the user's `groups` list in `locals.tf`.
2. Run the Terraform workflow.
3. Confirm the seat count under **Kiro → Access management → Subscriptions** — each member is
   billed at USD 20/month, allowing for the same up-to-24-hour propagation delay.

Re-check whether a first-class resource has shipped before assuming this is still the case:
[Subscribe your team](https://kiro.dev/docs/enterprise/subscribe/) ·
[Kiro enterprise IAM](https://kiro.dev/docs/enterprise/iam/)

### AWS Client VPN application
The custom SAML application used by AWS Client VPN is created here and assigned to the groups
listed in the local `client_vpn_groups`. Set `enable_sso_client_vpn = false` in `locals.tf` to
tear it down. The VPN endpoint itself lives in `network/us-east-1/client-vpn`.
