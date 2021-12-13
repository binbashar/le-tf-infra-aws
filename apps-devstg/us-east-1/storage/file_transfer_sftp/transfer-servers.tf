#
# Create an SFTP server
#
module "customer_sftp" {
  source = "github.com/binbashar/terraform-aws-sftp.git?ref=vpc-endpoint-and-more"

  name          = "${var.project}-${var.prefix}-customer-files"
  iam_role_name = "sftp-logging-role"

  endpoint_type = var.server_endpoint_type

  # Define server endpoint details when endpoint type is VPC
  endpoint_details = {
    vpc = {
      address_allocation_ids = [aws_eip.sftp_server[0].allocation_id]
      subnet_ids             = [data.terraform_remote_state.vpc.outputs.public_subnets[0]]
      vpc_id                 = data.terraform_remote_state.vpc.outputs.vpc_id
      security_group_ids     = [aws_security_group.sftp_server[0].id]
    }
  }

  protocols = var.server_protocols
  host_key  = var.server_host_key

  tags = local.tags
}

#
# Create a user-friendly DNS name for the SFTP server endpoint
#
resource "aws_route53_record" "main" {
  provider = aws.shared

  name    = "${var.project}-${var.prefix}-customers-sftp.binbash.com.ar"
  zone_id = data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id[0]
  type    = "CNAME"
  ttl     = "3600"
  records = [module.customer_sftp.sftp_server_endpoint]
}

#
# Elastic IP to associate to the server endpoint
#
resource "aws_eip" "sftp_server" {
  count = var.server_endpoint_type == "VPC" ? 1 : 0
  vpc   = true
}

#
# Security Group Settings
#
resource "aws_security_group" "sftp_server" {
  count       = var.server_endpoint_type == "VPC" ? 1 : 0
  name        = "${var.project}-${var.prefix}-customer-files"
  description = "SFTP Server Security Group Rules"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  tags        = local.tags
}
resource "aws_security_group_rule" "sftp_server_ingress" {
  count             = var.server_endpoint_type == "VPC" ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow All"
  security_group_id = aws_security_group.sftp_server[0].id
}
resource "aws_security_group_rule" "sftp_server_egress" {
  count             = var.server_endpoint_type == "VPC" ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow Egress All"
  security_group_id = aws_security_group.sftp_server[0].id
}
