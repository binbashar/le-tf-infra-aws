#
# Network Resources
#
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v3.1.0"

  name = local.vpc_name
  cidr = local.vpc_cidr_block

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway   = var.vpc_enable_nat_gateway
  single_nat_gateway   = var.vpc_single_nat_gateway
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  enable_vpn_gateway   = var.vpc_enable_vpn_gateway


  # Use a custom network ACL rules for private and public subnets
  manage_default_network_acl    = var.manage_default_network_acl
  public_dedicated_network_acl  = var.public_dedicated_network_acl  // use dedicated network ACL for the public subnets.
  private_dedicated_network_acl = var.private_dedicated_network_acl // use dedicated network ACL for the private subnets.
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )

  tags = local.tags
}

# VPC Endpoints
module "vpc_endpoints" {
  source = "github.com/binbashar/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v3.1.0"

  for_each = var.vpc_endpoints

  vpc_id = module.vpc.vpc_id

  endpoints = {
    endpoint = merge(each.value,
      {
        route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
      }
    )
  }

  tags = local.tags
}

#
# KMS VPC Endpoint: Security Group
#
resource "aws_security_group" "kms_vpce" {
  count       = length(lookup(var.vpc_endpoints, "kms", {})) > 0 ? 1 : 0
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
#
# Network Resources
#
#module "vpc" {
#  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v3.1.0"
#
#  name = local.vpc_name
#  cidr = local.vpc_cidr_block
#
#  azs             = local.azs
#  private_subnets = [] #local.private_subnets
#  public_subnets  = [] # No public subnets needed
#
#  enable_nat_gateway   = var.vpc_enable_nat_gateway
#  single_nat_gateway   = var.vpc_single_nat_gateway
#  enable_dns_hostnames = var.vpc_enable_dns_hostnames
#  enable_vpn_gateway   = var.vpc_enable_vpn_gateway
#
#
#  # Use a custom network ACL rules for private and public subnets
#  manage_default_network_acl    = var.manage_default_network_acl
#  public_dedicated_network_acl  = var.public_dedicated_network_acl  // use dedicated network ACL for the public subnets.
#  private_dedicated_network_acl = var.private_dedicated_network_acl // use dedicated network ACL for the private subnets.
#  private_inbound_acl_rules = concat(
#    local.network_acls["default_inbound"],
#    local.network_acls["private_inbound"],
#  )
#
#  tags = local.tags
#}

## Inspection VPC
module "inspection_vpc" {
  source                           = "cloudposse/vpc/aws"
  assign_generated_ipv6_cidr_block = false
  name                             = local.vpc_name
  cidr_block                       = local.vpc_cidr_block
  tags                             = local.tags
}

module "inspection_private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"

  name               = "inspection"
  vpc_id             = module.inspection_vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.inspection_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags

}

module "network_firewall_private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"

  name               = "firewall"
  vpc_id             = module.inspection_vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.network_firewall_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags
}
