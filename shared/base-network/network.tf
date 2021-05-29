#
# Network Resources
#
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v2.78.0"

  name = local.vpc_name
  cidr = local.vpc_cidr_block

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway       = var.vpc_enable_nat_gateway
  single_nat_gateway       = var.vpc_single_nat_gateway
  enable_dns_hostnames     = var.vpc_enable_dns_hostnames
  enable_vpn_gateway       = var.vpc_enable_vpn_gateway
  enable_s3_endpoint       = var.vpc_enable_s3_endpoint
  enable_dynamodb_endpoint = var.vpc_enable_dynamodb_endpoint

  enable_kms_endpoint              = var.enable_kms_endpoint
  kms_endpoint_private_dns_enabled = var.enable_kms_endpoint_private_dns
  kms_endpoint_security_group_ids  = var.enable_kms_endpoint ? [aws_security_group.kms_vpce[0].id] : []

  manage_default_network_acl    = var.manage_default_network_acl
  public_dedicated_network_acl  = var.public_dedicated_network_acl  // use dedicated network ACL for the public subnets.
  private_dedicated_network_acl = var.private_dedicated_network_acl // use dedicated network ACL for the private subnets.
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )

  tags = local.tags
}

#
# KMS VPC Endpoint: Security Group
#
resource "aws_security_group" "kms_vpce" {
  count       = var.enable_kms_endpoint ? 1 : 0
  name        = "kms_vpce"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
