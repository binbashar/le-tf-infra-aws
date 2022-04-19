# Asssociate Firewall Manager Service adminidtator account
resource "aws_fms_admin_account" "default" {
  account_id = var.security_account_id
}
