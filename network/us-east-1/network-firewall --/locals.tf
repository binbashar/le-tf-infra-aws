# Inspection VPC
locals {

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  vpc_name       = "${var.project}-${var.environment}-firewall-vpc"
  vpc_cidr_block = "172.20.16.0/20"
  azs = [
    "${var.region}a",
    #"${var.region}b",
    #"${var.region}c"
  ]

  # This includes the inspection and te firewall subnets
  private_subnets_cidr = ["172.20.16.0/20"]

  inspection_subnets_cidr = ["172.20.16.0/21"]
  inspection_subnets = [
    "172.20.16.0/23",
    #"172.20.18.0/23",
    #"172.20.20.0/23",
  ]

  network_firewall_subnets_cidr = ["172.20.24.0/21"]
  network_firewall_subnets = [
    "172.20.24.0/23",
    #"172.20.26.0/23",
    #"172.20.28.0/23",
  ]

  # AWS Network Firewall
  firewall_endpoints = [
    "${var.region}a",
    #"${var.region}b",
    #"${var.region}c"
  ]
}
