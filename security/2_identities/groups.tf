#
# Groups
#
resource "aws_iam_group" "admins" {
  name = "admins"
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

#
# Group / User Membership
#
resource "aws_iam_group_membership" "devops_members" {
  name = "devops_members"

  users = [
    module.user_alfredo_pardo.this_iam_user_name,
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
    module.user_gonzalo_martinez.this_iam_user_name,
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

resource "aws_iam_group_membership" "admins_members" {
  name = "admins_members"

  users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  group = aws_iam_group.admins.name
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

#
# Group Policy Attachments
#
resource "aws_iam_group_policy_attachment" "admins_have_assume_admin_role" {
  group      = aws_iam_group.admins.name
  policy_arn = aws_iam_policy.assume_admin_role.arn
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
