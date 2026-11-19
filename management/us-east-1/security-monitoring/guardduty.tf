#
# GuardDuty in the management account: foundational threat detection only.
#
# The detector is created here, before the delegation, so the management account
# owns its own detector and its protection plans are pinned off explicitly. The
# security account, as delegated admin, then adds this account as a member and
# auto-enables every other account (security/us-east-1/security-monitoring).
#
resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"

  tags = local.tags
}

# Every optional protection plan is explicitly disabled, not left to the API
# default: a detector created without a feature list enables some plans.
resource "aws_guardduty_detector_feature" "this" {
  for_each = local.guardduty_protection_plans

  detector_id = aws_guardduty_detector.this.id
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
# Designate the security account as GuardDuty's delegated administrator.
# AWS enables GuardDuty in the delegated admin account (in this Region) as a
# side effect, which is why the security layer reads that detector instead of
# creating it.
#
resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = var.accounts.security.id

  depends_on = [aws_guardduty_detector.this]
}
