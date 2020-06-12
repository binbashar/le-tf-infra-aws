#
# Groups
#
module "iam_group_admins" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "admins"

  group_users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_admin_role.arn,
  ]
}

module "iam_group_auditors" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "auditors"

  group_users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_auditor_role.arn,
  ]
}

module "iam_group_devops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "devops"

  group_users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_devops_role.arn,
  ]
}

module "iam_group_deploymaster" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "deploymaster"

  group_users = [
    module.user_circle_ci.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_deploymaster_role.arn,
  ]
}

module "iam_group_finops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "finops"

  group_users = [
    module.user_marcelo_beresvil.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_finops_role.arn,
  ]
}