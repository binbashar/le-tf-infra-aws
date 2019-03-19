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
    from_port   = 2709
    to_port     = 2709
    protocol    = "tcp"
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
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "pritunl.web.letsencrypt"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/20"]
    description = "vpc.security.account"
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