# Multi account with organizations
## Enable the security standards that Security Hub has designated as default:
## AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0
resource "aws_securityhub_organization_admin_account" "main" {
  depends_on = [aws_organizations_organization.main]

  admin_account_id = var.accounts.security.id
}

resource "aws_securityhub_finding_aggregator" "main" {
  linking_mode = "ALL_REGIONS"

  depends_on = [aws_securityhub_organization_admin_account.main]
}

resource "aws_securityhub_organization_configuration" "main" {
  auto_enable           = true
  auto_enable_standards = "DEFALT"
  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [aws_securityhub_finding_aggregator.main]
}