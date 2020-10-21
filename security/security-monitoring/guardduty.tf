#
# Enable GuardDuty in this account.
# Important: this needs to be imported as GuardDuty is automatically
# when you set this account as a delegated admin.
#
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
}

# Set auto_enable to true if you want GuardDuty to be enabled in all of your
# organization member accounts
resource "aws_guardduty_organization_configuration" "main" {
  auto_enable = false
  detector_id = aws_guardduty_detector.main.id
}

#
# Define explicitly all GuardDuty enabled accounts
# Note: a lifecycle is used because email and invite trigger changes every time.
#
resource "aws_guardduty_member" "shared" {
  account_id  = var.shared_account_id
  detector_id = aws_guardduty_detector.main.id
  email       = "binbash-aws-sr@binbash.com.ar"
  invite      = false
  lifecycle {
    ignore_changes = [email, invite]
  }
}
resource "aws_guardduty_member" "appsdevstg" {
  account_id  = var.appsdevstg_account_id
  detector_id = aws_guardduty_detector.main.id
  email       = "binbash-aws-dev@binbash.com.ar"
  invite      = false
  lifecycle {
    ignore_changes = [email, invite]
  }
}
resource "aws_guardduty_member" "appsprd" {
  account_id  = var.appsprd_account_id
  detector_id = aws_guardduty_detector.main.id
  email       = "info+binbash-aws-prd@binbash.com.ar"
  invite      = false
  lifecycle {
    ignore_changes = [email, invite]
  }
}
resource "aws_guardduty_member" "root" {
  account_id  = var.root_account_id
  detector_id = aws_guardduty_detector.main.id
  email       = "info@binbash.com.ar"
  invite      = false
  lifecycle {
    ignore_changes = [email, invite]
  }
}
