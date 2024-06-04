## Security Hub is administered via the Security Account, 
## which is designated as the administrator by the Management Account.
## Enable the security standards that Security Hub has designated as default:
## AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0
resource "aws_securityhub_organization_admin_account" "main" {
  admin_account_id = var.accounts.security.id
}