#
# AWS IAM Users (alphabetically ordered)
#
# Machine / Automation Users
#

#==========================#
# User: AuditorCI          #
#==========================#
module "user_auditor_ci" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v2.12.0"

  name                    = "auditor.ci"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = false
  create_iam_access_key         = true
  upload_iam_user_ssh_key       = false

  pgp_key = "${file("keys/auditor.ci")}"
}
