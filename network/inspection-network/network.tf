## Inspection VPC
module "vpc" {
  source                           = "cloudposse/vpc/aws"
  assign_generated_ipv6_cidr_block = false
  name                             = local.vpc_name
  cidr_block                       = local.vpc_cidr_block
  tags                             = local.tags
}

module "inspection_private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"

  name               = "inspection"
  vpc_id             = module.vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.inspection_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags

}

module "network_firewall_private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"

  name               = "firewall"
  vpc_id             = module.vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.network_firewall_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags
}
