locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  vpc_name       = "${var.project}-${var.environment}-inspection-vpc"
  vpc_cidr_block = "172.20.16.0/20"
  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  private_subnets_cidr = ["172.20.16.0/21"]
  private_subnets = [
    "172.20.16.0/23",
    "172.20.18.0/23",
    "172.20.20.0/23",
  ]

  public_subnets_cidr = ["172.20.24.0/21"]
  public_subnets = [
    "172.20.24.0/23",
    "172.20.26.0/23",
    "172.20.28.0/23",
  ]
}

locals {

  # private inbounds
  private_inbound = flatten([
    for index, state in local.datasources-vpcs : [
      {
        rule_number = 10 * (index(keys(local.datasources-vpcs), index) + 1)
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = state.outputs.private_subnets_cidr[0]
      }
    ]
  ])

  network_acls = {
    #
    # Allow / Deny VPC private subnets inbound default traffic
    #
    default_inbound = []

    #
    # Allow VPC private subnets inbound traffic
    #
    private_inbound = local.private_inbound
  }

  # Data source definitions
  #

  # network
  network-vpcs = {
    network-base = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/network/terraform.tfstate"
    }
  }

  datasources-vpcs = merge(
    data.terraform_remote_state.network-vpcs, # network
  )
}
