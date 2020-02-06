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
