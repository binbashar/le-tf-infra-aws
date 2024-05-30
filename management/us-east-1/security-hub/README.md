# AWS Security Hub

### Enable the security standards that Security Hub has designated as default:
### AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0

# For Single account use this:

```hcl
resource "aws_securityhub_account" "default" {
  enable_default_standards  = true
  auto_enable_controls      = true
  control_finding_generator = "SECURITY_CONTROL"
}
```


# Multi account with organization, use this:

```hcl
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
```

Note: It is recommended that the delegated account not be the `management` account. It is advised to use the `security` account as the delegated admin account.
