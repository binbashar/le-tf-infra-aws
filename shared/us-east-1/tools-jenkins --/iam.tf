#
# EC2 Profile (IAM Role)
#
resource "aws_iam_instance_profile" "basic_instance" {
  name = "${var.prefix}-${var.name}-instance-profile"
  role = aws_iam_role.jenkins_master_instance_assume_role.name
}

# This policies allows Jenkins EC2 to assume a IAM role
#
resource "aws_iam_role" "jenkins_master_instance_assume_role" {
  name               = "${var.prefix}-${var.name}-instance-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role policy attachment
#
resource "aws_iam_role_policy_attachment" "jenkins_master_host_account" {
  role       = aws_iam_role.jenkins_master_instance_assume_role.name
  policy_arn = aws_iam_policy.jenkins_master_host_account.arn
}

resource "aws_iam_role_policy_attachment" "jenkins_master_cross_org_instance_access" {
  role       = aws_iam_role.jenkins_master_instance_assume_role.name
  policy_arn = aws_iam_policy.jenkins_master_cross_org_instance_access.arn
}

#
# The following policy fulfills the requirement of the Ansible Certbot role that
# takes care of creating and renewing LetsEncrypt certificates.
#
resource "aws_iam_policy" "jenkins_master_host_account" {
  name        = "${var.prefix}-${var.name}-shared"
  description = "Access policy for Jenkins Master"
  policy      = data.aws_iam_policy_document.jenkins_master.json
}

data "aws_iam_policy_document" "jenkins_master" {
  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_public_zone_id[0]}"
    ]
  }
}

# This policy allow Jenkins Master EC2 to assume AWS cross-org-accounts roles
#
resource "aws_iam_policy" "jenkins_master_cross_org_instance_access" {
  name        = "${var.prefix}-${var.name}-cross-org-instance-policy"
  description = "Access policy for basic_instance"
  policy      = data.aws_iam_policy_document.cross_org_instance_access.json
}

data "aws_iam_policy_document" "cross_org_instance_access" {
  policy_id = "instanceCrossAccountPolicyID"

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    resources = [
      "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DeployMaster",
      "arn:aws:iam::${var.appsprd_account_id}:role/DeployMaster",
      "arn:aws:iam::${var.accounts.shared.id}:role/DeployMaster",
      "arn:aws:iam::${var.accounts.apps-devstg.id}:role/Auditor",
      "arn:aws:iam::${var.appsprd_account_id}:role/Auditor",
      "arn:aws:iam::${var.accounts.shared.id}:role/Auditor",
      "arn:aws:iam::${var.accounts.security.id}:role/Auditor"
    ]

    sid = "ec2AssumeRoleCrossAccountStatementID"
  }
}

