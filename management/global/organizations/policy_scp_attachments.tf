# Import default FullAWSAccess SCP
resource "aws_organizations_policy_attachment" "default_fullawsaccess_ou" {
  for_each = local.organizational_units

  policy_id = "p-FullAWSAccess"
  target_id = aws_organizations_organizational_unit.units[each.key].id
}

import {
  for_each = local.organizational_units

  id = "${aws_organizations_organizational_unit.units[each.key].id}:p-FullAWSAccess"
  to = aws_organizations_policy_attachment.default_fullawsaccess_ou[each.key]
}


resource "aws_organizations_policy_attachment" "default_fullawsaccess_accounts" {
  for_each = local.accounts

  policy_id = "p-FullAWSAccess"
  target_id = aws_organizations_account.accounts[each.key].id
}

import {
  for_each = local.accounts

  id = "${aws_organizations_account.accounts[each.key].id}:p-FullAWSAccess"
  to = aws_organizations_policy_attachment.default_fullawsaccess_accounts[each.key]
}

resource "aws_organizations_policy_attachment" "default_fullawsaccess_root" {
  policy_id = "p-FullAWSAccess"
  target_id = aws_organizations_account.root.id
}

import {
  id = "${aws_organizations_account.root.id}:p-FullAWSAccess"
  to = aws_organizations_policy_attachment.default_fullawsaccess_root
}

#
# Organizational Units' Policies
#
resource "aws_organizations_policy_attachment" "policy_attachments" {
  for_each = local.organizational_units

  policy_id = each.value.policy.id
  target_id = aws_organizations_organizational_unit.units[each.key].id

  depends_on = [
    aws_organizations_organizational_unit.units
  ]
}

#
# Delete protection policy attachment
#
resource "aws_organizations_policy_attachment" "delete_protection" {

  for_each = { for v in [
    "network",
    "bbl_apps_devstg",
    "bbl_apps_prd",
    "shared",
  ] : v => v }

  policy_id = aws_organizations_policy.delete_protection.id
  target_id = aws_organizations_organizational_unit.units[each.value].id
}

#
# Tag protection policy attachment
#
resource "aws_organizations_policy_attachment" "tag_protection" {

  for_each = { for v in [
    "network",
    "bbl_apps_devstg",
    "bbl_apps_prd",
    "shared",
  ] : v => v }

  policy_id = aws_organizations_policy.tag_protection.id
  target_id = aws_organizations_organizational_unit.units[each.value].id
}
