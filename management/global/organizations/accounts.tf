#
# Organization accounts
#

# Root account of the organization: mainly used for consolidated billing reports
#  but it could also be used to manage the SCPs of the OUs and accounts.
#
resource "aws_organizations_account" "root" {
  name  = "${var.project_long}-management"
  email = local.management_account.email
}

#
# Creates the AWS Organizations Accounts based on configurations in locals.tf
#
resource "aws_organizations_account" "accounts" {
  for_each = local.accounts

  name      = "${var.project_long}-${each.key}"
  email     = each.value.email
  parent_id = aws_organizations_organizational_unit.units[each.value.parent_ou].id
}

data "aws_iam_roles" "shared" {
  provider = aws.shared
  name_regex = "AWSReservedSSO_DevOps.*"
}

data "aws_iam_roles" "network" {
  provider = aws.network
  name_regex = "AWSReservedSSO_DevOps.*"
}

data "aws_iam_roles" "apps-devstg" {
  provider = aws.apps-devstg
  name_regex = "AWSReservedSSO_DevOps.*"
}

data "aws_iam_roles" "apps-prd" {
  provider = aws.apps-prd
  name_regex = "AWSReservedSSO_DevOps.*"
}