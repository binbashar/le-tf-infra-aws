#
# Groups
#
resource "aws_iam_group" "admins" {
    name = "admins"
}

resource "aws_iam_group" "devops" {
    name = "devops"
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
        "${module.user_diego_ojeda.this_iam_user_name}",
        "${module.user_marcos_pagnuco.this_iam_user_name}",
        "${module.user_exequiel_barrirero.this_iam_user_name}"
    ]

    group = "${aws_iam_group.devops.name}"
}

resource "aws_iam_group_membership" "admins_members" {
    name = "admins_members"

    users = [
        "${module.user_diego_ojeda.this_iam_user_name}",
        "${module.user_marcos_pagnuco.this_iam_user_name}",
        "${module.user_exequiel_barrirero.this_iam_user_name}"
    ]

    group = "${aws_iam_group.admins.name}"
}

resource "aws_iam_group_membership" "auditors_members" {
    name = "auditors_members"

    users = [
        "${module.user_diego_ojeda.this_iam_user_name}",
        "${module.user_marcos_pagnuco.this_iam_user_name}",
        "${module.user_exequiel_barrirero.this_iam_user_name}"
    ]

    group = "${aws_iam_group.auditors.name}"
}

#
# Group Policy Attachments
#
resource "aws_iam_group_policy_attachment" "admins_have_administrator_access" {
    group      = "${aws_iam_group.admins.name}"
    policy_arn = "${aws_iam_policy.assume_admin_role.arn}"
//    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "devops_have_standard_console_user" {
    group      = "${aws_iam_group.devops.name}"
    policy_arn = "${aws_iam_policy.standard_console_user.arn}"
}

resource "aws_iam_group_policy_attachment" "devops_have_assume_devops_role" {
    group      = "${aws_iam_group.devops.name}"
    policy_arn = "${aws_iam_policy.assume_devops_role.arn}"
}

resource "aws_iam_group_policy_attachment" "auditors_have_assume_auditor_role" {
    group      = "${aws_iam_group.auditors.name}"
    policy_arn = "${aws_iam_policy.assume_auditor_role.arn}"
}