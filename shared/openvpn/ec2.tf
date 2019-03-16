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

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh traffic"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
    description = "ssh"
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
    description = "node.exporter"
  }
  ingress {
    from_port   = 15255
    to_port     = 15255
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "pritunl.server.dev"
  }
  ingress {
    from_port   = 11080
    to_port     = 11080
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "pritunl.server.admin"
  }
  ingress {
    from_port   = 2709
    to_port     = 2709
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "pritunl.server.dev"
  }
  ingress {
    from_port   = 17458
    to_port     = 17458
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "pritunl.server.bi"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "pritunl.web.letsencrypt"
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "nginx.spinnaker.gate"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
    description = "vpc.security.account"
  }
  ingress {
    from_port   = 17758
    to_port     = 17758
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = "${local.tags}"
}

resource "aws_security_group" "pritunl_temporary_access" {
  name        = "pritunl_temporary_access"
  description = "Allow temporary access to Printunl 443"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
    description = "security.vpc"
  }

  tags = "${local.tags}"
}

resource "aws_route53_record" "pritunl" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "pritunl.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.openvpn_instance.private_ip}"]
}

resource "aws_route53_record" "webhooks" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "webhooks.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.openvpn_instance.public_ip}"]
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

resource "aws_instance" "openvpn_instance" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t3.small"
  vpc_security_group_ids = ["${list(aws_security_group.allow_ssh.id, aws_security_group.pritunl_temporary_access.id)}"]
  subnet_id = "${data.terraform_remote_state.vpc.public_subnets[0]}"
  key_name = "deployer-infra"

  tags = "${local.tags}"

  lifecycle {
    ignore_changes = ["ami"]
  }
}

resource "aws_eip" "this" {
  instance = "${aws_instance.openvpn_instance.id}"
  vpc      = true
}