module "account_assignments" {
  source = "github.com/binbashar/terraform-aws-sso.git//modules/account-assignments?ref=0.6.1"

  account_assignments = [
    # -------------------------------------------------------------------------
    # AWS_Administrators Permissions
    # -------------------------------------------------------------------------
    {
      account             = var.accounts.root.id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_Administrators"
    },
    {
      account             = var.accounts.shared.id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_Administrators"
    },
    {
      account             = var.accounts.security.id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_Administrators"
    },
    {
      account             = var.accounts.network.id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_Administrators"
    },
    {
      account             = var.accounts.apps-devstg.id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_Administrators"
    },
    {
      account             = var.accounts.apps-prd.id,
      permission_set_arn  = module.permission_sets.permission_sets["Administrator"].arn,
      permission_set_name = "Administrator",
      principal_type      = "GROUP",
      principal_name      = "AWS_Administrators"
    },

    # -------------------------------------------------------------------------
    # AWS_DevOps Permissions
    # -------------------------------------------------------------------------
    {
      account             = var.accounts.shared.id,
      permission_set_arn  = module.permission_sets.permission_sets["DevOps"].arn,
      permission_set_name = "DevOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.accounts.security.id,
      permission_set_arn  = module.permission_sets.permission_sets["DevOps"].arn,
      permission_set_name = "DevOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.accounts.network.id,
      permission_set_arn  = module.permission_sets.permission_sets["DevOps"].arn,
      permission_set_name = "DevOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.accounts.apps-devstg.id,
      permission_set_arn  = module.permission_sets.permission_sets["DevOps"].arn,
      permission_set_name = "DevOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },
    {
      account             = var.accounts.apps-prd.id,
      permission_set_arn  = module.permission_sets.permission_sets["DevOps"].arn,
      permission_set_name = "DevOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_DevOps"
    },

    # -------------------------------------------------------------------------
    # AWS_FinOps Permissions
    # -------------------------------------------------------------------------
    {
      account             = var.accounts.root.id,
      permission_set_arn  = module.permission_sets.permission_sets["FinOps"].arn,
      permission_set_name = "FinOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_FinOps"
    },

    # -------------------------------------------------------------------------
    # AWS_SecOps Permissions
    # -------------------------------------------------------------------------
    {
      account             = var.accounts.shared.id,
      permission_set_arn  = module.permission_sets.permission_sets["SecOps"].arn,
      permission_set_name = "SecOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.accounts.security.id,
      permission_set_arn  = module.permission_sets.permission_sets["SecOps"].arn,
      permission_set_name = "SecOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.accounts.network.id,
      permission_set_arn  = module.permission_sets.permission_sets["SecOps"].arn,
      permission_set_name = "SecOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.accounts.apps-devstg.id,
      permission_set_arn  = module.permission_sets.permission_sets["SecOps"].arn,
      permission_set_name = "SecOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },
    {
      account             = var.accounts.apps-prd.id,
      permission_set_arn  = module.permission_sets.permission_sets["SecOps"].arn,
      permission_set_name = "SecOps",
      principal_type      = "GROUP",
      principal_name      = "AWS_SecOps"
    },

    # -------------------------------------------------------------------------
    # AWS_Guests Permissions
    # -------------------------------------------------------------------------
    {
      account             = var.accounts.shared.id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.accounts.security.id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.accounts.network.id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.accounts.apps-devstg.id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    },
    {
      account             = var.accounts.apps-prd.id,
      permission_set_arn  = module.permission_sets.permission_sets["ReadOnly"].arn,
      permission_set_name = "ReadOnly",
      principal_type      = "GROUP",
      principal_name      = "AWS_Guests"
    }
    ,
    # -------------------------------------------------------------------------
    # AWS_Marketplace Permissions
    # -------------------------------------------------------------------------

    {
      account             = var.accounts.root.id,
      permission_set_arn  = module.permission_sets.permission_sets["MarketplaceSeller"].arn,
      permission_set_name = "MarketplaceSeller",
      principal_type      = "GROUP",
      principal_name      = "AWS_MarketplaceSeller"
    },
  ]
}
