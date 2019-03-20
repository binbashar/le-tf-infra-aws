#
# Security Resources
#

#
# Security Groups
#
module "sg_private" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/sg-bb?ref=v0.5"

  // udp_ports        = "22,443,9100"
  security_group_name     = "${var.sg_private_name}"
  tcp_ports               = "${var.sg_private_tpc_ports}"
  cidrs                   = ["${var.sg_private_cidrs}"]
  vpc_id                  = "${data.terraform_remote_state.vpc.vpc_id}"

  tags                    = "${local.tags}"
}

//
// AWS EC2 profile w/ IAM Role association
//
resource "aws_iam_instance_profile" "jenkins" {
  name = "JenkinsProfile"
  role = "${aws_iam_role.jenkins_assume_role.name}"
}

resource "aws_iam_role" "jenkins_assume_role" {
  name = "JenkinsAssumeRole"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "jenkins_access" {
    name        = "JenkinsAccessPolicy"
    description = "Access policy for Jenkins"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:*",
                "ssm:*",
                "route53:*",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "sts:AssumeRole",
            "Resource": [
                "arn:aws:iam::${var.dev_account_id}:role/DeployMaster",
                "arn:aws:iam::${var.shared_account_id}:role/DeployMaster",
                "arn:aws:iam::${var.security_account_id}:role/DeployMaster",
                "arn:aws:iam::${var.dev_account_id}:role/Auditor",
                "arn:aws:iam::${var.shared_account_id}:role/Auditor",
                "arn:aws:iam::${var.security_account_id}:role/Auditor"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_all" {
    role       = "${aws_iam_role.jenkins_assume_role.name}"
    policy_arn = "${aws_iam_policy.jenkins_access.arn}"
}