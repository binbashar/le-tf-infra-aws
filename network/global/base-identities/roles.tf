#
# IAM Roles
#

#
# Assumable Role Cross-Account: DevOps
#
module "iam_assumable_role_devops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.1.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.security_account_id}:root"
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
# Assumable Role Cross-Account: SecOps
#
module "iam_assumable_role_secops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.1.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.security_account_id}:root"
  ]

  create_role = true
  role_name   = "SecOps"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = true
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of valid MFA (in seconds) for roles which require MFA
  custom_role_policy_arns = [
    aws_iam_policy.secops_access.arn
  ]

  tags = local.tags
}

#
# Assumable Role Cross-Account: Admin
#
module "iam_assumable_role_admin" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.1.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.security_account_id}:root"
  ]

  create_role           = true
  role_name             = "Admin"
  admin_role_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  attach_admin_policy   = true
  role_path             = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = true
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of valid MFA (in seconds) for roles which require MFA

  tags = local.tags
}

#
# Assumable Role Cross-Account: Auditor Role
#
module "iam_assumable_role_auditor" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.1.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.security_account_id}:root"
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
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.1.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.security_account_id}:root",
    "arn:aws:iam::${var.network_account_id}:root"
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
# Assumable Role Cross-Account: Grafana
#
module "iam_assumable_role_grafana" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.1.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.shared_account_id}:root"
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

  tags = local.tags
}
