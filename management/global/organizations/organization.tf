#
# Organization
#
resource "aws_organizations_organization" "main" {
  # Not needed at first, might be needed later: https://docs.aws.amazon.com/organizations/latest/APIReference/API_EnableAWSServiceAccess.html
  aws_service_access_principals = [
    "malware-protection.guardduty.amazonaws.com",
    "guardduty.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "aws-artifact-account-sync.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "ram.amazonaws.com",
    "sso.amazonaws.com",
    "fms.amazonaws.com",
    "inspector2.amazonaws.com",
  ]

  # Enable all feature set to enable SCPs
  feature_set = "ALL"

  # Enable Service Control Policies to enable custom SCPs
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "BACKUP_POLICY"
  ]
}

#
# Delegate administration of access analyzer to security account
#
resource "aws_organizations_delegated_administrator" "access_analyzer_administrator" {
  account_id        = aws_organizations_account.accounts["security"].id
  service_principal = "access-analyzer.amazonaws.com"

  depends_on = [
    aws_organizations_organization.main,
    aws_organizations_account.accounts["security"]
  ]
}

resource "aws_iam_service_linked_role" "access_analyzer" {
  aws_service_name = "access-analyzer.amazonaws.com"
}
