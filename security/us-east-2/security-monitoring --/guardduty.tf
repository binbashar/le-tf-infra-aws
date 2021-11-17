#
# GuardDuty is enabled in this account as a delegated admin
#
module "guardduty" {
  source = "github.com/binbashar/terraform-aws-guardduty-multiaccount.git//modules/multiaccount-setup?ref=v0.0.9"

  guarduty_enabled                           = true
  guarduty_s3_protection_enabled             = true
  guardduty_organization_members_auto_enable = false
  guardduty_member_accounts = {
    shared = {
      account_id = var.shared_account_id
      email      = "binbash-aws-sr@binbash.com.ar"
    },
    appsdevstg = {
      account_id = var.appsdevstg_account_id
      email      = "binbash-aws-dev@binbash.com.ar"
    },
    appsprd = {
      account_id = var.appsprd_account_id
      email      = "info+binbash-aws-prd@binbash.com.ar"
    },
    root = {
      account_id = var.root_account_id
      email      = "info@binbash.com.ar"
    }
  }
}
