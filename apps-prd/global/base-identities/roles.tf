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
  max_session_duration = 3600  # Max age of valid MFA (in seconds) for roles which require MFA
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
    "arn:aws:iam::${var.accounts.security.id}:root"
  ]

  create_role = true
  role_name   = "DeployMaster"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = false
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of valid MFA (in seconds) for roles which require MFA
  custom_role_policy_arns = [
    aws_iam_policy.deploy_master_access.arn
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
# Assumable Role: AWSServiceRoleForOrganizations
#
module "iam_assumable_role_service_organizations" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

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


}

#
# Assumable Role: AWSServiceRoleForSupport
#
module "iam_assumable_role_service_support" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

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


}

#
# Assumable Role: AWSServiceRoleForTrustedadvisor
#
module "iam_assumable_role_service_trustedadvisor" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

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
# Drata Auditor (Compliance Provider)
#
module "iam_assumable_role_drata_auditor" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.external_accounts.drata.aws_account_id}:root"
  ]

  role_sts_externalid = [
    var.external_accounts.drata.aws_external_id
  ]

  create_role      = true
  role_name        = "DrataAutopilotRole"
  role_description = "Cross-account read-only access for Drata Autopilot"
  role_path        = "/"

  role_requires_mfa = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/SecurityAudit"
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
