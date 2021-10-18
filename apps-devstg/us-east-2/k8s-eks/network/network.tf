#
# EKS VPC
#
module "vpc-eks" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v3.7.0"

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
  manage_default_network_acl    = false
  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  tags                = local.tags
}

# VPC Endpoints
module "vpc_endpoints" {
  source = "github.com/binbashar/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v3.1.0"

  for_each = var.vpc_endpoints

  vpc_id = module.vpc-eks.vpc_id

  endpoints = {
    endpoint = merge(each.value,
      {
        route_table_ids = concat(module.vpc-eks.private_route_table_ids, module.vpc-eks.public_route_table_ids)
      }
    )
  }

  tags = local.tags
}
