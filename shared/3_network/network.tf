#
# Network Resources
#
module "vpc" {
  source = "git::git@github.com:binbashar/terraform-aws-vpc.git?ref=v2.21.0"

  name = local.vpc_name
  cidr = local.vpc_cidr_block

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_vpn_gateway   = false

  tags = local.tags
}
