#
# EKS VPC
#
module "vpc-eks" {
  source = "git::git@github.com:binbashar/terraform-aws-vpc.git?ref=v2.18.0"

  name = local.vpc_name
  cidr = local.vpc_cidr_block

  azs                  = local.azs
  private_subnets      = local.private_subnets
  public_subnets       = local.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_vpn_gateway   = false

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  tags                = local.tags
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc-eks.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = local.mgmt_worker_subnets
  }
}