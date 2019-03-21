#
# Network Resources
#
module "vpc" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/vpc-tf?ref=v0.5"

    name = "${local.vpc_name}"
    cidr = "${local.vpc_cidr_block}"

    azs             = "${local.azs}"
    private_subnets = "${local.private_subnets}"
    public_subnets  = "${local.public_subnets}"

    enable_nat_gateway   = true
    single_nat_gateway   = true
    enable_vpn_gateway   = false
    enable_dns_hostnames = true

    tags = "${local.tags}"
}