#
# Assumable Role Cross-Account: OrganizationAccountAccessRole
#
module "iam_assumable_role_oaar" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.management.id}:root"
  ]

  create_role           = true
  role_name             = "OrganizationAccountAccessRole"
  admin_role_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  attach_admin_policy   = true
  role_path             = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = true
  mfa_age              = 3600 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 7200 # Max age of the session (in seconds) when assuming roles


}

#
# Assumable Role: Costs Explorer access
#
module "iam_assumable_role_lambda_costs_explorer_access" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.shared.id}:root",
    "arn:aws:iam::${var.accounts.shared.id}:role/monthly-services-usage-lambdarole"
  ]

  create_role = true
  role_name   = "LambdaCostsExplorerAccess"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = false
  mfa_age              = 86400 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 10800 # Max age of the session (in seconds) when assuming roles
  custom_role_policy_arns = [
    aws_iam_policy.lambda_costs_explorer_access.arn,
  ]


}

#
# Assumable Role: north.cloud
#
module "iam_assumable_role_north_cloud_access" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.external_accounts.north_cloud.aws_account_id}:root"
  ]

  create_role = true
  role_name   = "NorthCostAndUsageRole"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = false
  mfa_age              = 86400 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 10800 # Max age of the session (in seconds) when assuming roles
  custom_role_policy_arns = [
    aws_iam_policy.north_cloud_tool_access.arn,
  ]
}

#
# Assumable Role Cross-Account: DeployMaster
#
module "iam_assumable_role_deploy_master" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root",
  ]

  create_role = true
  role_name   = "DeployMaster"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = false
  mfa_age              = 86400 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 10800 # Max age of the session (in seconds) when assuming roles
  custom_role_policy_arns = [
    aws_iam_policy.deploy_master_access.arn
  ]
}

#
# Cross-Account Role: Atlantis
#
module "iam_assumable_role_atlantis" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  create_role       = true
  role_name         = "Atlantis"
  role_requires_mfa = false

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root",
  ]

  # Use inline only if you anticipate you won't need to reuse the same policy statements
  inline_policy_statements = [
    {
      sid = "Baseline"
      actions = [
        "dynamodb:*",
        "events:*",
        "iam:*",
        "kms:*",
        "logs:*",
        "s3:*",
        "lambda:*",
        "organizations:Describe*",
        "organizations:List*",
        "sso:ListInstances",
      ]
      effect    = "Allow"
      resources = ["*"]
      conditions = [
        {
          test     = "StringEquals"
          values   = var.regions_allowed
          variable = "aws:RequestedRegion"
        }
      ]
    }
  ]
}
