#------------------------------------------------------------------------------
# Amazon Quick (formerly Amazon QuickSight) account subscription
#------------------------------------------------------------------------------
# Native IAM Identity Center integration: Quick reads group membership straight
# from the organization instance, so granting a seat means adding a user to the
# matching group in management/global/sso. There is no console step.
#
# This choice is one-way. AWS cannot move a live subscription to a different
# access approach (SAML federation, identity pool) without cancelling it, and
# Quick namespaces stay unavailable for as long as it is in force.
# Ref: https://docs.aws.amazon.com/prescriptive-guidance/latest/quick-suite-access-approach/iam-identity-center-integration.html
#------------------------------------------------------------------------------
resource "aws_quicksight_account_subscription" "this" {
  account_name          = var.quick_account_name
  edition               = var.quick_edition
  authentication_method = "IAM_IDENTITY_CENTER"
  notification_email    = var.quick_notification_email

  iam_identity_center_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]

  # Bootstrap only -- see locals.tf. Never edit this in place: every argument on
  # this resource is ForceNew and there is no Update, so a change plans a
  # destroy/create of the entire subscription. New mappings belong below.
  admin_group = [local.quick_admin_group]

  depends_on = [data.aws_identitystore_group.quick]

  lifecycle {
    # A paid subscription that cannot be replaced without losing every asset it
    # holds. This turns the ForceNew hazard above into a hard plan failure.
    #
    # It does NOT keep the subscription alive, and dropping it does not retire
    # anything: while this resource stays declared, `apply` leaves the
    # subscription in place and it keeps billing. Retiring the layer takes an
    # explicit, reviewed `destroy` -- see the README.
    prevent_destroy = true
  }
}

#------------------------------------------------------------------------------
# Group -> role mappings
#------------------------------------------------------------------------------
# The durable management surface. Unlike the subscription above these are added
# and removed freely, so every mapping other than the bootstrap admin group
# belongs here.
#
# Role memberships are only available to subscriptions authenticating through
# IAM Identity Center or Active Directory -- the API is disabled for identities
# managed by Quick itself.
#------------------------------------------------------------------------------
resource "aws_quicksight_role_membership" "this" {
  for_each = local.quick_role_memberships

  member_name = each.value
  role        = each.key

  depends_on = [aws_quicksight_account_subscription.this]
}
