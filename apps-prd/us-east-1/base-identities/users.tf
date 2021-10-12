#
# AWS IAM Users (alphabetically ordered)
#
# Machine / Automation Users
#

#==========================#
# User: AuditorCI          #
#==========================#
module "user_auditor_ci" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "modded_auditor.ci"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = false
  create_iam_access_key         = true
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/machine.auditor.ci")
}
