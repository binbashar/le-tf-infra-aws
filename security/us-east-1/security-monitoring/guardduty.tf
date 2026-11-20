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

  # AWS reports per-plan sub-configurations (RDS_DATA_RISK, *_AGENT_MANAGEMENT...)
  # that are not set here; without this every plan would replace the feature.
  # They follow the parent, which is off.
  lifecycle {
    ignore_changes = [additional_configuration]
  }
}

#
# Never auto-enable a protection plan in any member account. Set before the
# membership below, so no account is enrolled while a plan is still auto-enabled.
#
# NONE only governs enablement: it does not turn off a plan an account already
# has. That happened on the first rollout (S3 came back on in four accounts with
# an older GuardDuty history), so member plans are also disabled explicitly below.
#
resource "aws_guardduty_organization_configuration_feature" "this" {
  for_each = local.guardduty_protection_plans

  detector_id = data.aws_guardduty_detector.this.id
  name        = each.value
  auto_enable = "NONE"

  # AWS reports per-plan sub-configurations (RDS_DATA_RISK, *_AGENT_MANAGEMENT...)
  # that are not set here; without this every plan would replace the feature.
  # They follow the parent, which is off.
  lifecycle {
    ignore_changes = [additional_configuration]
  }
}

#
# Auto-enable GuardDuty in every account of the organization, existing and new
# (ALL), so no account list has to be kept in sync. AWS may take up to 24 hours
# to roll the configuration out to every member.
#
resource "aws_guardduty_organization_configuration" "this" {
  detector_id                      = data.aws_guardduty_detector.this.id
  auto_enable_organization_members = "ALL"

  depends_on = [aws_guardduty_organization_configuration_feature.this]
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

#
# Disable every protection plan on every member account explicitly. ALL with
# auto-enable NONE did not turn off plans some accounts had from an earlier
# GuardDuty setup, so this re-asserts the foundational-only state on each apply.
#
# An account added to var.accounts is enrolled by ALL within up to 24 hours;
# until then it is not a member and applying this fails for it. Accounts outside
# var.accounts are caught by the README (Verify) coverage check.
#
resource "aws_guardduty_member_detector_feature" "this" {
  for_each = local.guardduty_member_plans

  detector_id = data.aws_guardduty_detector.this.id
  account_id  = var.accounts[each.value.account].id
  name        = each.value.plan
  status      = "DISABLED"

  # Same sub-configuration drift as the features above.
  lifecycle {
    ignore_changes = [additional_configuration]
  }

  depends_on = [aws_guardduty_organization_configuration.this]
}
