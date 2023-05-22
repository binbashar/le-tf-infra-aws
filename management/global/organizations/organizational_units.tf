#
# Organizational Units
#
resource "aws_organizations_organizational_unit" "units" {
  for_each = local.organizational_units

  name      = each.key
  parent_id = aws_organizations_organization.main.roots.0.id

  depends_on = [
    aws_organizations_organization.main
  ]
}
