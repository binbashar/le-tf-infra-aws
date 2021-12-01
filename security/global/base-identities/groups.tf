#
# Groups
#
module "iam_group_admins" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "admins"

  group_users = [
    module.user_diego_ojeda.iam_user_name,
    module.user_exequiel_barrirero.iam_user_name,
    module.user_marcos_pagnuco.iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_admin_role.arn,
  ]
}

module "iam_group_auditors" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "auditors"

  group_users = [
    module.user_diego_ojeda.iam_user_name,
    module.user_exequiel_barrirero.iam_user_name,
    module.user_marcos_pagnuco.iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_auditor_role.arn,
  ]
}

module "iam_group_devops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "devops"

  group_users = [
    module.user_angelo_fenoglio.iam_user_name,
    module.user_diego_ojeda.iam_user_name,
    module.user_exequiel_barrirero.iam_user_name,
    module.user_jose_peinado.iam_user_name,
    module.user_luis_gallardo.iam_user_name,
    module.user_marcos_pagnuco.iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_devops_role.arn,
  ]
}

module "iam_group_finops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "finops"

  attach_iam_self_management_policy = false

  group_users = [
    module.user_marcelo_beresvil.iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_finops_role.arn,
    aws_iam_policy.restricted_iam_self_management.arn,
  ]
}

module "iam_group_secops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "secops"

  group_users = [
    module.user_angelo_fenoglio.iam_user_name,
    module.user_diego_ojeda.iam_user_name,
    module.user_exequiel_barrirero.iam_user_name,
    module.user_jose_peinado.iam_user_name,
    module.user_luis_gallardo.iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_secops_role.arn,
  ]
}

#
# Machine users groups
#
module "iam_group_deploymaster" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "deploymaster"

  group_users = [
    module.user_circle_ci.iam_user_name,
    module.user_github_actions.iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_deploymaster_role.arn,
  ]
}

module "iam_group_s3_demo" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "s3_demo"

  attach_iam_self_management_policy = false

  group_users = [
    module.user_s3_demo.iam_user_name,
  ]

  custom_group_policies = [
    {
      name   = "AllowS3PutObject"
      policy = data.aws_iam_policy_document.s3_demo_put_object.json
    },
  ]
}
