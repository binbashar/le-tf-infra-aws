## Inspection VPC
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc-base?ref=2.0.0"

  assign_generated_ipv6_cidr_block = false
  name                             = local.vpc_name
  ipv4_primary_cidr_block          = local.vpc_cidr_block
  tags                             = local.tags
}

module "inspection_private_subnets" {
  source = "github.com/binbashar/terraform-aws-multi-az-subnets?ref=0.15.0"

  name               = "${var.project}-${var.environment}-inspection"
  vpc_id             = module.vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.inspection_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags
}

module "network_firewall_private_subnets" {
  source = "github.com/binbashar/terraform-aws-multi-az-subnets?ref=0.15.0"

  name               = "${var.project}-${var.environment}-firewall"
  vpc_id             = module.vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.network_firewall_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags
}
