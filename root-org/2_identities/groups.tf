#
# Groups
#
resource "aws_iam_group" "admins" {
  name = "admins_root_org"
}

resource "aws_iam_group" "finops" {
  name = "finops_root_org"
}

#
# Group / User Membership
#
resource "aws_iam_group_membership" "admins_members" {
  name = "admins_members"

  users = [
    module.user_diego_ojeda.this_iam_user_name,
    module.user_marcos_pagnuco.this_iam_user_name,
    module.user_exequiel_barrirero.this_iam_user_name,
  ]

  group = aws_iam_group.admins.name
}

resource "aws_iam_group_membership" "finops_members" {
  name = "finops_members"

  users = [
    module.user_marcelo_beresvil.this_iam_user_name,
  ]

  group = aws_iam_group.finops.name
}

#
# Group Policy Attachments
#
resource "aws_iam_group_policy_attachment" "admins_have_administrator_access" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "finops_have_billing_access" {
  group      = aws_iam_group.finops.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

resource "aws_iam_group_policy_attachment" "finops_have_standard_console_user" {
  group      = aws_iam_group.finops.name
  policy_arn = aws_iam_policy.standard_console_user.arn
}
