#
# Network Resources
#
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v2.71.0"

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

  manage_default_network_acl    = false
  public_dedicated_network_acl  = true // use dedicated network ACL for the public subnets.
  private_dedicated_network_acl = true // use dedicated network ACL for the private subnets.
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  tags                = local.tags
}
