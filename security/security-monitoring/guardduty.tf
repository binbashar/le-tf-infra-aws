#
# GuardDuty is enabled in this account as a delegated admin
#
# IMPORTANT: Enabling S3 Protection is not supported by Terraform AWS provider yet.
# The following issue is already open regarding that:
# https://github.com/terraform-providers/terraform-provider-aws/issues/14607
#
module "guardduty" {
  source = "github.com/binbashar/terraform-aws-guardduty-multiaccount.git//multiaccount-setup"

  guarduty_enabled                           = true
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
