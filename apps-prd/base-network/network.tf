#
# Network Resources
#
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v2.55.0"

  name = local.vpc_name
  cidr = local.vpc_cidr_block

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway   = false
  single_nat_gateway   = false # if false 1 NGW x AZ (3 x NGWs)
  enable_dns_hostnames = true
  enable_vpn_gateway   = false

  manage_default_network_acl    = false
  public_dedicated_network_acl  = true // use dedicated network ACL for the public subnets.
  private_dedicated_network_acl = true // use dedicated network ACL for the private subnets.
  private_inbound_acl_rules     = concat(
  local.network_acls["default_inbound"],
  local.network_acls["private_inbound"],
  )

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  tags                = local.tags
}
