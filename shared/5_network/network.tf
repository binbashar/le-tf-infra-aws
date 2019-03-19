#
# Network Resources
#
module "vpc" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/vpc-tf?ref=v0.3"

    name = "${var.project}-${var.environment}-vpc"
    cidr = "172.17.0.0/20"

    azs             = ["us-east-1a", "us-east-1b"]
    private_subnets = [
        "172.17.0.0/23",
        "172.17.2.0/23"
    ]
    public_subnets  = [
        "172.17.6.0/23",
        "172.17.8.0/23"
    ]

    enable_nat_gateway = true
    single_nat_gateway = true
    enable_vpn_gateway = false
    enable_dns_hostnames = true

    tags = "${local.tags}"
}
