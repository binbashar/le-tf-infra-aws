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
  mfa_age              = 3600 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 7200 # Max age of the session (in seconds) when assuming roles

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


#
# Assumable Role: Costs Explorer access
#
module "iam_assumable_role_lambda_costs_explorer_access" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.3.3"

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

  tags = local.tags
}

#
# Assumable Role: north.cloud
#
module "iam_assumable_role_north_cloud_access" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.3.3"

  trusted_role_arns = [
    "arn:aws:iam::480850768557:root" # Specify the AWS account ID where the trusted account resides
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

  tags = local.tags
}



