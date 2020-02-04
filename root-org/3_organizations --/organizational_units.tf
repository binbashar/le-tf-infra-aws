#
# Security: this is for centralized security access
#
resource "aws_organizations_organizational_unit" "security" {
  name      = "security"
  parent_id = aws_organizations_organization.main.roots.0.id
}

#
# Shared: this is for shared resources -- although another option could be to
# have a shared account per business unit (e.g. project, and others)
#
resource "aws_organizations_organizational_unit" "shared" {
  name      = "shared"
  parent_id = aws_organizations_organization.main.roots.0.id
}

#
# Apps DevStg: this is for applications and services under your Project.
#
resource "aws_organizations_organizational_unit" "apps_devstg" {
  name      = "apps_devstg"
  parent_id = aws_organizations_organization.main.roots.0.id
}

#
# Apps Prd: this is for applications and services under your Project.
#
resource "aws_organizations_organizational_unit" "apps_prd" {
  name      = "apps_prd"
  parent_id = aws_organizations_organization.main.roots.0.id
}
