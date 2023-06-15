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
