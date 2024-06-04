# AWS Security Hub

# This layer is only necessary for multi-account setups within an organization.
# Before running this layer, you must first execute the 'security-hub' layer in the management account.

```hcl
resource "aws_securityhub_organization_admin_account" "main" {
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
```