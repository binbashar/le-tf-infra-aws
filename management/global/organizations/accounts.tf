#
# Root account of the organization: mainly used for consolidated billing reports
#  but it could also be used to manage the SCPs of the OUs and accounts.
#
resource "aws_organizations_account" "root" {
  name  = "binbash-root"
  email = "aws+root@binbash.com.ar"
}

#
# Security: this is a centralized account that we can use to grant
#  permissions over the other accounts.
#
resource "aws_organizations_account" "security" {
  name      = "binbash-security"
  email     = "aws+security@binbash.com.ar"
  parent_id = aws_organizations_organizational_unit.security.id
}

#
# Shared: this account will be used to host shared resources that are consumed
#  or provide services to the other accounts.
#
resource "aws_organizations_account" "shared" {
  name      = "binbash-shared"
  email     = "aws+shared@binbash.com.ar"
  parent_id = aws_organizations_organizational_unit.shared.id
}

#
# Networks: this account will be used to host network resources that are consumed
#  or provide services to the other accounts.
#
resource "aws_organizations_account" "network" {
  name      = "binbash-network"
  email     = "aws+network@binbash.com.ar"
  parent_id = aws_organizations_organizational_unit.network.id
}

#
# Project DevStg: services and resources related to development/stage are
#  placed and maintained here.
#
resource "aws_organizations_account" "apps_devstg" {
  name      = "binbash-apps-devstg"
  email     = "aws+apps-devstg@binbash.com.ar"
  parent_id = aws_organizations_organizational_unit.bbl_apps_devstg.id
}

#
# Project Prd: services and resources related to production are placed and
#  maintained here.
#
resource "aws_organizations_account" "apps_prd" {
  name      = "binbash-apps-prd"
  email     = "aws+apps-prd@binbash.com.ar"
  parent_id = aws_organizations_organizational_unit.bbl_apps_prd.id
}
