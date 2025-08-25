#
# Groups
#
module "iam_group_admins" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v5.60.0"
  name   = "admins_root_org"

  group_users = [
    module.user["angelo.fenoglio"].iam_user_name,
    module.user["diego.ojeda"].iam_user_name,
    module.user["exequiel.barrirero"].iam_user_name,
    module.user["jose.peinado"].iam_user_name,
    module.user["luis.gallardo"].iam_user_name,
    module.user["matias.rodriguez"].iam_user_name,
  ]

  custom_group_policy_arns = [
    aws_iam_policy.assume_oaar_role.arn
  ]
}

module "iam_group_finops" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v5.60.0"
  name   = "finops_root_org"

  group_users = [
    module.user["marcelo.beresvil"].iam_user_name
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/Billing",
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
  ]
}

module "iam_group_aws_iq" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v5.60.0"
  name   = "aws_iq_root_org"

  group_users = [
    module.user["emiliano.brest"].iam_user_name,
    module.user["marcos.pagnucco"].iam_user_name
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AWSIQFullAccess",
    "arn:aws:iam::aws:policy/AWSMarketplaceSellerFullAccess"
  ]
}
