#
# We must first enable GuardDuty in the root account so it can be enabled
# later from GuardDuty's delegated admin.
#
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
}

#
# Designate Security account as GuardDuty's delegated admin
#
resource "aws_guardduty_organization_admin_account" "security" {
  admin_account_id = var.security_account_id
}
