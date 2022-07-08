#
# GuardDuty is enabled in this account as a delegated admin
#
module "guardduty" {
  source = "github.com/binbashar/terraform-aws-guardduty-multiaccount.git//modules/multiaccount-setup?ref=v0.1.0"

  # Activating Guardduty & S3 protection in this account (security-account).
  guarduty_enabled               = true
  guarduty_s3_protection_enabled = true

  # New Org Accounts will have Guardduty & S3 Protection automatically enabled
  guardduty_organization_members_auto_enable               = true
  guardduty_organization_members_s3_protection_auto_enable = true

  # Pre-existing Org Accounts (already members) have to be declared below
  guardduty_member_accounts = {
    root = {
      account_id = var.accounts.root.id
      email      = "info@binbash.com.ar"
    },
    shared = {
      account_id = var.shared_account_id
      email      = "binbash-aws-sr@binbash.com.ar"
    },
    network = {
      account_id = var.network_account_id
      email      = "binbash-aws-net@binbash.com.ar"
    },
    appsdevstg = {
      account_id = var.appsdevstg_account_id
      email      = "binbash-aws-dev@binbash.com.ar"
    },
    appsprd = {
      account_id = var.appsprd_account_id
      email      = "info+binbash-aws-prd@binbash.com.ar"
    }
  }
}
