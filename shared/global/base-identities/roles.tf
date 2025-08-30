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
    "arn:aws:iam::${var.accounts.security.id}:root"
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
# Assumable Role Cross-Account: FinOps Role
#
module "iam_assumable_role_finops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root"
  ]

  create_role            = false
  role_name              = "FinOps"
  attach_readonly_policy = true
  role_path              = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = true
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of the session (in seconds) when assuming roles
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
    aws_iam_policy.s3_put_gdrive_to_s3_backup.arn,
  ]


}

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
  mfa_age              = 7200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600 # Max age of the session (in seconds) when assuming roles


}

#------------------------------------------------------------------------------
# Github OIDC Integration
#------------------------------------------------------------------------------
locals {
  # Only grant permission to assume this role to this repo/branch
  github_oidc_allowed_branches = [
    "repo:binbashar/demo-google-microservices:ref:refs/heads/master",
    "repo:binbashar/le-emojivoto:ref:refs/heads/master",
  ]
}

resource "aws_iam_role" "github_actions_role" {
  name        = "${local.environment}-github-actions-oidc"
  description = "Github OIDC integration for Github Actions"
  tags        = merge(local.tags, { Name = "github-oidc-workflows" })
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "GithubActionsAssumeRoleWithIdp",
        Effect = "Allow",
        Action = [
          "sts:AssumeRoleWithWebIdentity"
        ],
        Principal = {
          Federated = aws_iam_openid_connect_provider.aws_github_oidc.arn
        },
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.github_oidc_allowed_branches,
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  # Had to add this because Tofu kept wanting to apply the same tags updates everytime
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_oidc" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_oidc.arn
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
        "athena:*",
        "budgets:*",
        "cloudfront:*",
        "cloudtrail:*",
        "cloudwatch:*",
        "config:*",
        "dynamodb:*",
        "ec2:*",
        "ecr:*",
        "elasticloadbalancing:*",
        "glue:*",
        "iam:*",
        "kms:*",
        "logs:*",
        "organizations:Describe*",
        "organizations:List*",
        "route53:*",
        "route53domains:*",
        "s3:*",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:Describe*",
        "sns:*",
        "ssm:*",
        "sqs:*",
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
