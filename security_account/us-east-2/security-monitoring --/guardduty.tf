#
# GuardDuty is enabled in this account as a delegated admin
#
module "guardduty" {
  source = "github.com/binbashar/terraform-aws-guardduty-multiaccount.git//modules/multiaccount-setup?ref=v0.2.1"

  # Activating Guardduty & S3 protection in this account (security-account).
  guarduty_enabled                       = true
  guarduty_s3_protection_enabled         = true
  guarduty_kubernetes_protection_enabled = false
  guarduty_malware_protection_enabled    = false

  # New Org Accounts will have Guardduty & S3 Protection automatically enabled
  guardduty_organization_members_auto_enable                    = true
  guardduty_organization_members_s3_protection_auto_enable      = true
  guardduty_organization_members_kubernetes_protection_enable   = false
  guardduty_organization_members_malware_protection_auto_enable = false

  # Pre-existing Org Accounts (already members) have to be declared below
  guardduty_member_accounts = {
    root = {
      account_id = var.accounts.root.id
      email      = "info@binbash.com.ar"
    },
    shared = {
      account_id = var.accounts.shared.id
      email      = "binbash-aws-sr@binbash.com.ar"
    },
    network = {
      account_id = var.accounts.network.id
      email      = "binbash-aws-net@binbash.com.ar"
    },
    appsdevstg = {
      account_id = var.accounts.apps-devstg.id
      email      = "binbash-aws-dev@binbash.com.ar"
    },
    appsprd = {
      account_id = var.accounts.apps-prd.id
      email      = "info+binbash-aws-prd@binbash.com.ar"
    }
  }
}
