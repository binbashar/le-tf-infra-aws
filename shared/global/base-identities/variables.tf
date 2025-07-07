#
# AWS IAM Users (alphabetically ordered)
#
# Machine / Automation Users
#

#==========================#
# User: AuditorCI          #
#==========================#
variable "users" {
  description = "Map of users to create"
  type = map(object({
    name                          = string
    force_destroy                 = bool
    password_reset_required       = bool
    create_iam_user_login_profile = bool
    create_iam_access_key         = bool
    upload_iam_user_ssh_key       = bool
    pgp_key                       = string
  }))
  default = {
    auditor_ci = {
      name                          = "auditor.ci"
      force_destroy                 = true
      password_reset_required       = true
      create_iam_user_login_profile = false
      create_iam_access_key         = true
      upload_iam_user_ssh_key       = false
      pgp_key                       = "keys/machine.auditor.ci"
    }
  }
}
