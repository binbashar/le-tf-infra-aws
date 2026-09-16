locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }

  #----------------------------------------------------------------------------
  # Amazon Quick role <- IAM Identity Center group (display name)
  #----------------------------------------------------------------------------
  # The groups themselves live in management/global/sso/locals.tf, alongside
  # `kiropro`, and are bound to no permission set: membership grants a Quick
  # seat and nothing else.
  #
  # ADMIN is bound by the subscription resource itself, because
  # CreateAccountSubscription requires at least one admin group at signup. Every
  # argument on that resource is ForceNew and the provider implements no Update,
  # so it is set once and never touched again.
  #
  # Every other role is a role membership, which is created and destroyed
  # freely. To map a new group -- or a Pro tier, once the provider is on 6.x --
  # add a line to `quick_role_memberships`; the subscription is never re-planned.
  #
  quick_admin_group = "QuickAdmin"

  # NOTE A role membership only persists if its group already has a member.
  # Verified on this account at signup: QuickAdmin and QuickAuthor (one member
  # each) stuck, while QuickReader (empty) was accepted by CreateRoleMembership
  # -- tofu reported "Creation complete" -- and then silently dropped by
  # QuickSight. That leaves the resource in state, absent in AWS, and re-planning
  # `1 to add` on every run. So map a group here only once somebody is in it.
  #
  # Granting the *first* reader is therefore two edits rather than one: add the
  # user to `quickreader` in management/global/sso, then add
  # `READER = "QuickReader"` below. Subsequent readers are the usual one-liner.
  #
  quick_role_memberships = {
    AUTHOR = "QuickAuthor"
  }

  # Every group this layer depends on, for the existence guard in sso-groups.tf.
  quick_groups = toset(concat([local.quick_admin_group], values(local.quick_role_memberships)))
}
