#------------------------------------------------------------------------------
# IAM Identity Center lookups (management account)
#------------------------------------------------------------------------------
# Amazon Quick is subscribed here, in data-science, but authenticates against the
# organization instance of IAM Identity Center, which lives in management. AWS
# supports exactly this split -- the account only has to belong to the same
# organization, and Quick has to run in the same region as the instance.
# Ref: https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/publishing-as-sso-application.html
#------------------------------------------------------------------------------
data "aws_ssoadmin_instances" "this" {
  provider = aws.management
}

#
# Existence guard for the Identity Center groups this layer maps to Quick roles.
# The groups are defined in management/global/sso, which must be applied first.
# Resolving them here turns a missing or mistyped group name into a plan error
# rather than a permanently mis-bound subscription: `admin_group` is ForceNew on
# a resource that cannot be replaced without cancelling the subscription and
# losing every asset in it.
#
data "aws_identitystore_group" "quick" {
  provider = aws.management

  for_each = local.quick_groups

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value
    }
  }
}
