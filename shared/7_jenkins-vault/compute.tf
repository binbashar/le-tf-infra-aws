data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

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

resource "template_file" "userdata" {
  template = "${file("userdata.sh")}"
}

# Note: this resource was imported for tagging purposes only.
resource "aws_ebs_volume" "root" {
  availability_zone = "us-east-1a"
  size = 8
  type = "gp2"
  tags = "${merge(local.tags, map("Backup", "True"))}"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ebs_volume" "jenkins-data" {
  availability_zone = "us-east-1a"
  size = 100
  type = "gp2"
  tags = "${merge(local.tags, map("Backup", "True"))}"
}

resource "aws_ebs_volume" "docker-data" {
  availability_zone = "us-east-1a"
  size = 100
  type = "gp2"
  tags = "${merge(local.tags, map("Backup", "True"))}"
}

resource "aws_instance" "jenkins-vault_instance" {

  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t3.large"
  vpc_security_group_ids = ["${aws_security_group.jenkins-vault.id}"]
  subnet_id = "${data.terraform_remote_state.vpc.private_subnets[0]}"
  key_name = "deployer-infra"
  user_data = "${template_file.userdata.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.jenkins.id}"

  tags = "${local.tags}"

  lifecycle {
    ignore_changes = ["ami"]
  }
}

resource "aws_volume_attachment" "jenkins_ebs_att_1" {
    device_name = "/dev/sdh"
    volume_id = "${aws_ebs_volume.jenkins-data.id}"
    instance_id = "${aws_instance.jenkins-vault_instance.id}"
}
resource "aws_volume_attachment" "jenkins_ebs_att_2" {
    device_name = "/dev/sdi"
    volume_id = "${aws_ebs_volume.docker-data.id}"
    instance_id = "${aws_instance.jenkins-vault_instance.id}"
}

#
# DNS
#
resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "jenkins.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}
resource "aws_route53_record" "vault" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "vault.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}
resource "aws_route53_record" "devsecops" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "devsecops.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}

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
                "arn:aws:iam::${var.dev_account_id}:role/JenkinsMaster",
                "arn:aws:iam::${var.appsprd_account_id}:role/JenkinsMaster",
                "arn:aws:iam::${var.dev_account_id}:role/Auditor",
                "arn:aws:iam::${var.appsprd_account_id}:role/Auditor",
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