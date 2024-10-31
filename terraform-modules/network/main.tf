#
# EKS VPC
#
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v5.5.3"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs             = local.azs_internal
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

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

  # disable all ingress/egress from the default security group
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  tags                = local.tags
}


