#
# GuardDuty organization setup, run from the security account (delegated admin).
# Foundational threat detection only: no optional protection plans.
#
# The detector is read, not created: designating this account as delegated
# admin (management/us-east-1/security-monitoring) makes AWS enable GuardDuty
# here, so creating it would fail and importing it would be a manual step.
# Apply the management layer first.
#
data "aws_guardduty_detector" "this" {}

resource "aws_guardduty_detector_feature" "this" {
  for_each = local.guardduty_protection_plans

  detector_id = data.aws_guardduty_detector.this.id
  name        = each.value
  status      = "DISABLED"
}

#
# Auto-enable GuardDuty in every account of the organization, existing and new
# (ALL), so no account list has to be kept in sync. AWS may take up to 24 hours
# to roll the configuration out to every member.
#
resource "aws_guardduty_organization_configuration" "this" {
  detector_id                      = data.aws_guardduty_detector.this.id
  auto_enable_organization_members = "ALL"
}

# ...but never auto-enable a protection plan in any of them.
resource "aws_guardduty_organization_configuration_feature" "this" {
  for_each = local.guardduty_protection_plans

  detector_id = data.aws_guardduty_detector.this.id
  name        = each.value
  auto_enable = "NONE"

  depends_on = [aws_guardduty_organization_configuration.this]
}

#
# The management account keeps its own detector (created in its layer) and is
# associated explicitly; ALL is only documented to cover member accounts and the
# delegated admin.
#
resource "aws_guardduty_member" "management" {
  account_id  = var.accounts.management.id
  detector_id = data.aws_guardduty_detector.this.id
  email       = var.accounts.management.email
  invite      = false

  # Email and invite are only used when the membership is created.
  lifecycle {
    ignore_changes = [email, invite]
  }

  depends_on = [aws_guardduty_organization_configuration.this]
}
