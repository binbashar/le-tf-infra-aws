# Inspection VPC
locals {

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  vpc_name       = "${var.project}-${var.environment}-firewall-dr-vpc"
  vpc_cidr_block = "172.20.48.0/20"
  azs = [
    "${var.region_secondary}a",
    #"${var.region_secondary}b",
    #"${var.region_secondary}c"
  ]

  # This includes the inspection and te firewall subnets
  private_subnets_cidr = ["172.20.48.0/20"]

  inspection_subnets_cidr = ["172.20.48.0/21"]
  inspection_subnets = [
    "172.20.48.0/23",
    #"172.20.50.0/23",
    #"172.20.52.0/23",
  ]

  network_firewall_subnets_cidr = ["172.20.56.0/21"]
  network_firewall_subnets = [
    "172.20.56.0/23",
    #"172.20.58.0/23",
    #"172.20.60.0/23",
  ]

  # AWS Network Firewall
  firewall_endpoints = [
    "${var.region_secondary}a",
    #"${var.region_secondary}b",
    #"${var.region_secondary}c"
  ]
}
