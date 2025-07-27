#
# IAM Roles
#

#
# Assumable Role Cross-Account: DevOps
#
module "iam_assumable_role_devops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root"
  ]

  create_role = true
  role_name   = "DevOps"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = true
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of valid MFA (in seconds) for roles which require MFA
  custom_role_policy_arns = [
    aws_iam_policy.devops_access.arn
  ]
}

#
# Assumable Role Cross-Account: Auditor Role
#
module "iam_assumable_role_auditor" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.data-science.id}:root"
  ]

  create_role            = true
  role_name              = "Auditor"
  attach_readonly_policy = true
  role_path              = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = false
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of the session (in seconds) when assuming roles
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/SecurityAudit"
  ]
}

#
# Assumable Role Cross-Account: DeployMaster
#
module "iam_assumable_role_deploy_master" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root",
    "arn:aws:iam::${var.accounts.network.id}:root",
    "arn:aws:iam::${var.accounts.data-science.id}:root",
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
# Assumable Role Cross-Account: Grafana
#
module "iam_assumable_role_grafana" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.shared.id}:root"
  ]

  create_role = true
  role_name   = "Grafana"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = false
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of valid MFA (in seconds) for roles which require MFA
  custom_role_policy_arns = [
    aws_iam_policy.grafana_permissions.arn
  ]
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
# Cross-Account Role: Atlantis
#
module "iam_assumable_role_atlantis" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.59.0"

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
        "acm:*",
        "apigateway:*",
        "autoscaling:*",
        "aws-portal:*",
        "cloudformation:*",
        "cloudfront:*",
        "cloudtrail:*",
        "cloudwatch:*",
        "config:*",
        "dlm:*",
        "dynamodb:*",
        "ec2:*",
        "ecs:*",
        "elasticloadbalancing:*",
        "events:*",
        "health:*",
        "iam:*",
        "kms:*",
        "lambda:*",
        "logs:*",
        "organizations:Describe*",
        "organizations:List*",
        "rds:*",
        "redshift:*",
        "route53:*",
        "s3:*",
        "secretsmanager:GetSecretValue",
        "secretsmanager:Describe*",
        "sns:*",
        "sqs:*",
        "ssm:*",
        "support:*",
        "tag:*",
        "trustedadvisor:*",
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
