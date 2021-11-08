module "account_assignments" {
  source = "github.com/binbashar/terraform-aws-sso.git//modules/account-assignments?ref=0.6.1"

  account_assignments = [
    # ------------------------------
    # AWS_Administrators Permissions
    # ------------------------------
    {
      account             = var.root_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_Administrators"
    },

    # ----------------------
    # AWS_DevOps Permissions
    # ----------------------
    {
      account             = var.shared_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.security_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.network_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.appsdevstg_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.appsprd_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },

    # ----------------------
    # AWS_FinOps Permissions
    # ----------------------
    {
      account             = var.root_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["FinOps"].arn,
      permission_set_name = "FinOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_FinOps"
    },

    # ----------------------
    # AWS_SecOps Permissions
    # ----------------------
    {
      account             = var.shared_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SecurityAuditor"].arn,
      permission_set_name = "SecurityAuditor",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.security_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SecurityAuditor"].arn,
      permission_set_name = "SecurityAuditor",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.network_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SecurityAuditor"].arn,
      permission_set_name = "SecurityAuditor",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.appsdevstg_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SecurityAuditor"].arn,
      permission_set_name = "SecurityAuditor",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.appsprd_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["SecurityAuditor"].arn,
      permission_set_name = "SecurityAuditor",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },

    # ----------------------
    # AWS_Guests Permissions
    # ----------------------
    {
      account             = var.shared_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.security_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.network_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.appsdevstg_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.appsprd_account_id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
  ]
}
