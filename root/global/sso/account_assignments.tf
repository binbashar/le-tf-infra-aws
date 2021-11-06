module "account_assignments" {
  source = "github.com/binbashar/terraform-aws-sso.git//modules/account-assignments?ref=0.6.1"

  enabled = true
  account_assignments = [
    #
    # DevOps Permissions on non-Management accounts
    #
    {
      account             = var.shared_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SysAdmins"].arn,
      permission_set_name = "SysAdmins",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.security_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SysAdmins"].arn,
      permission_set_name = "SysAdmins",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.network_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SysAdmins"].arn,
      permission_set_name = "SysAdmins",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.appsdevstg_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SysAdmins"].arn,
      permission_set_name = "SysAdmins",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.appsprd_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SysAdmins"].arn,
      permission_set_name = "SysAdmins",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
  ]
}
