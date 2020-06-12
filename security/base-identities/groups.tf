#
# Groups
#
module "iam_group_admins" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "admins_root_org"

  group_users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
    aws_iam_policy.assume_admin_role.arn,
  ]
}

resource "aws_iam_group" "devops" {
  name = "devops"
}

resource "aws_iam_group" "deploymaster" {
  name = "deploymaster"
}

resource "aws_iam_group" "auditors" {
  name = "auditors"
}

//module "iam_group_finops" {
//  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
//  name = "finops_root_org"
//
//  group_users = [
//    module.user_marcelo_beresvil.this_iam_user_name,
//  ]
//
//  custom_group_policy_arns = [
//    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
//  ]
//}

#
# Group / User Membership
#
resource "aws_iam_group_membership" "devops_members" {
  name = "devops_members"

  users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  group = aws_iam_group.devops.name
}

resource "aws_iam_group_membership" "deploymaster_members" {
  name = "deploymaster_members"

  users = [
    module.user_circle_ci.this_iam_user_name,
  ]

  group = aws_iam_group.deploymaster.name
}

resource "aws_iam_group_membership" "auditors_members" {
  name = "auditors_members"

  users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  group = aws_iam_group.auditors.name
}

resource "aws_iam_group_policy_attachment" "devops_have_standard_console_user" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.standard_console_user.arn
}

resource "aws_iam_group_policy_attachment" "devops_have_assume_devops_role" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.assume_devops_role.arn
}

resource "aws_iam_group_policy_attachment" "deploymaster_have_assume_deploymaster_role" {
  group      = aws_iam_group.deploymaster.name
  policy_arn = aws_iam_policy.assume_deploymaster_role.arn
}

resource "aws_iam_group_policy_attachment" "auditors_have_assume_auditor_role" {
  group      = aws_iam_group.auditors.name
  policy_arn = aws_iam_policy.assume_auditor_role.arn
}
