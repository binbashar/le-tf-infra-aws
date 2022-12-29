#
# IAM Roles
#

#
# Assumable Role Cross-Account: DevOps
#
module "iam_assumable_role_devops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

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

  tags = local.tags
}

#
# Assumable Role Cross-Account: Auditor Role
#
module "iam_assumable_role_auditor" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

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

  tags = local.tags
}

#
# Assumable Role Cross-Account: DeployMaster
#
module "iam_assumable_role_deploy_master" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root",
    "arn:aws:iam::${var.accounts.shared.id}:root"
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

  tags = local.tags
}


#
# Assumable Role Cross-Account: FinOps Role
#
module "iam_assumable_role_finops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root"
  ]

  create_role            = true
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

  tags = local.tags
}

#
# Assumable Role Cross-Account: OrganizationAccountAccessRole
#
module "iam_assumable_role_oaar" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.root.id}:root"
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

  tags = local.tags
}

#
# Assumable Role: AWSServiceRoleForOrganizations
#
module "iam_assumable_role_service_organizations" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

  trusted_role_services = [
    "organizations.amazonaws.com"
  ]

  create_role      = true
  role_name        = "AWSServiceRoleForOrganizations"
  role_description = "Service-linked role used by AWS Organizations to enable integration of other AWS services with Organizations."
  role_path        = "/aws-service-role/organizations.amazonaws.com/"

  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/aws-service-role/AWSOrganizationsServiceTrustPolicy"
  ]

  tags = local.tags
}

#
# Assumable Role: AWSServiceRoleForSupport
#
module "iam_assumable_role_service_support" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

  trusted_role_services = [
    "support.amazonaws.com"
  ]

  create_role      = true
  role_name        = "AWSServiceRoleForSupport"
  role_description = "Enables resource access for AWS to provide billing, administrative and support services"
  role_path        = "/aws-service-role/support.amazonaws.com/"

  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/aws-service-role/AWSSupportServiceRolePolicy"
  ]

  tags = local.tags
}

#
# Assumable Role: AWSServiceRoleForTrustedadvisor
#
module "iam_assumable_role_service_trustedadvisor" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.9.2"

  trusted_role_services = [
    "trustedadvisor.amazonaws.com"
  ]

  create_role      = true
  role_name        = "AWSServiceRoleForTrustedAdvisor"
  role_description = "Access for the AWS Trusted Advisor Service to help reduce cost, increase performance, and improve security of your AWS environment."
  role_path        = "/aws-service-role/trustedadvisor.amazonaws.com/"

  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/aws-service-role/AWSTrustedAdvisorServiceRolePolicy"
  ]

  tags = local.tags
}


#------------------------------------------------------------------------------
# Github OIDC Integration
#------------------------------------------------------------------------------
locals {
  # Only grant permission to assume this role to this repo/branch
  github_oidc_allowed_branches = "repo:binbashar/demo-google-microservices:ref:refs/heads/master"
}

resource "aws_iam_role" "github_actions_role" {
  name               = "${local.environment}-github-actions-oidc"
  description        = "Github OIDC integration for Github Actions"
  tags               = merge(local.tags, { Name = "github-oidc-workflows" })
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GithubActionsAssumeRoleWithIdp",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRoleWithWebIdentity"
      ],
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.aws_github_oidc.arn}"
      },
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:sub": "${local.github_oidc_allowed_branches}",
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_actions_oidc" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_oidc.arn
}
