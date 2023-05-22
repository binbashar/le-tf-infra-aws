#
# Organization accounts
#

# Root account of the organization: mainly used for consolidated billing reports
#  but it could also be used to manage the SCPs of the OUs and accounts.
#
resource "aws_organizations_account" "root" {
  name  = "${var.project_long}-root"
  email = local.root_account.email
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
