locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
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

  quick_role_memberships = {
    AUTHOR = "QuickAuthor"
    READER = "QuickReader"
  }

  # Every group this layer depends on, for the existence guard in sso-groups.tf.
  quick_groups = toset(concat([local.quick_admin_group], values(local.quick_role_memberships)))
}
