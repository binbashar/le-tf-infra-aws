# Asssociate Firewall Manager Service adminidtator account
resource "aws_fms_admin_account" "default" {
  account_id = var.accounts.security.id
}
