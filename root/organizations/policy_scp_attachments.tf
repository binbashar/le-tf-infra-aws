#
# Security Organizational Unit Policies
#
resource "aws_organizations_policy_attachment" "security" {
  policy_id = aws_organizations_policy.default.id
  target_id = aws_organizations_organizational_unit.security.id
}

#
# Shared Organizational Unit Policies
#
resource "aws_organizations_policy_attachment" "shared" {
  policy_id = aws_organizations_policy.standard.id
  target_id = aws_organizations_organizational_unit.shared.id
}

#
# Networks Organizational Unit Policies
#
resource "aws_organizations_policy_attachment" "network" {
  policy_id = aws_organizations_policy.default.id
  target_id = aws_organizations_organizational_unit.network.id
}

#
# Project Organizational Unit Policies (should cover devstg)
#
resource "aws_organizations_policy_attachment" "apps_devstg" {
  policy_id = aws_organizations_policy.standard.id
  target_id = aws_organizations_organizational_unit.bbl_apps_devstg.id
}

#
# Project Organizational Unit Policies (should cover prd)
#
resource "aws_organizations_policy_attachment" "apps_prd" {
  policy_id = aws_organizations_policy.standard.id
  target_id = aws_organizations_organizational_unit.bbl_apps_prd.id
}

#
# Delete protection policy attachment
#
resource "aws_organizations_policy_attachment" "delete_protection" {

  for_each = { for v in [aws_organizations_organizational_unit.network] : v.id => v.id }
  #for_each = aws_organizations_organizational_unit

  policy_id = aws_organizations_policy.delete_protection.id
  target_id = each.key
}
