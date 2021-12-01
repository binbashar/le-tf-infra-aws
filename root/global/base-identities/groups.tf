#
# Groups
#
module "iam_group_admins" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "admins_root_org"

  group_users = [
    module.user_angelo_fenoglio.iam_user_name,
    module.user_diego_ojeda.iam_user_name,
    module.user_exequiel_barrirero.iam_user_name,
    module.user_jose_peinado.iam_user_name,
    module.user_luis_gallardo.iam_user_name,
    module.user_marcos_pagnuco.iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}

module "iam_group_finops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v4.7.0"
  name   = "finops_root_org"

  group_users = [
    module.user_marcelo_beresvil.iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/Billing",
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
  ]
}
