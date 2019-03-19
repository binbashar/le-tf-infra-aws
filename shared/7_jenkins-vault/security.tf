//
// EC2 Security Group w/ ingress/egress rules
//
resource "aws_security_group" "jenkins-vault" {
  name        = "jenkins-vault"
  description = "Allow access to services on Jenkins/vault server"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20","172.17.48.0/20"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
  }
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = "${local.tags}"
}


//
// AWS EC2 profile w/ IAM Role association
//
resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins_profile"
  role = "${aws_iam_role.jenkins_assume_role.name}"
}

resource "aws_iam_role" "jenkins_assume_role" {
  name = "jenkins_assume_role"
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
    name        = "jenkins-access-policy"
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