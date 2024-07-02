
resource "aws_securityhub_finding_aggregator" "main" {
  linking_mode = "ALL_REGIONS"
}

resource "aws_securityhub_organization_configuration" "main" {
  auto_enable           = false
  auto_enable_standards = "NONE"
  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [aws_securityhub_finding_aggregator.main]
}

resource "aws_securityhub_configuration_policy" "org_policy" {
  name        = "org_policy"
  description = "This is a configuration policy"

  configuration_policy {
    service_enabled = true
    enabled_standard_arns = [
      "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
      "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    ]
    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }

  depends_on = [aws_securityhub_organization_configuration.main]
}

resource "aws_securityhub_configuration_policy_association" "root_policy_association" {
  target_id = data.aws_organizations_organization.this.roots[0].id
  policy_id = aws_securityhub_configuration_policy.org_policy.id
}