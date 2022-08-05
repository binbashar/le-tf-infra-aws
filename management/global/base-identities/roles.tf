#
# Assumable Role Cross-Account: OrganizationAccountAccessRole
#
module "iam_assumable_role_oaar" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.7.0"

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
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.23.0"

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
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.23.0"

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
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.23.0"

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