#
# Groups
#
resource "aws_iam_group" "admins" {
  name = "admins_root_org"
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

#
# Group Policy Attachments
#
resource "aws_iam_group_policy_attachment" "admins_have_administrator_access" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
