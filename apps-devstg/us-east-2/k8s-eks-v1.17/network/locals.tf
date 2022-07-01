locals {
  cluster_name = "${var.project}-${var.environment}-eks-v117-2ry"

  vpc_name = "${var.project}-${var.environment}-vpc-eks-v117-2ry"
  # Ref: https://www.davidc.net/sites/default/subnets/subnets.html?network=10.10.0.0&mask=16&division=15.7231
  vpc_cidr_block = "10.10.0.0/16"
  azs = [
    "${var.region_secondary}a",
    "${var.region_secondary}b",
    "${var.region_secondary}c",
  ]

  private_subnets_cidr = ["10.10.0.0/17"]
  private_subnets = [
    "10.10.0.0/19",
    "10.10.32.0/19",
    "10.10.64.0/19",
    #"10.10.96.0/19",
  ]

  public_subnets_cidr = ["10.10.128.0/17"]
  public_subnets = [
    "10.10.128.0/19",
    "10.10.160.0/19",
    "10.10.192.0/19",
    #"10.10.224.0/19",
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # We need these so that k8s aws cloud provider recognizes our private subnets
  # and associates them to any load balancer that is created
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

locals {
  # private inbounds
  private_inbound = flatten([
    for index, state in local.datasources-vpcs : [
      for k, v in state.outputs.private_subnets_cidr :
      {
        rule_number = 10 * (index(keys(local.datasources-vpcs), index) + 1) + 100 * k
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = state.outputs.private_subnets_cidr[k]
      }
    ]
  ])

  network_acls = {
    #
    # Allow / Deny VPC private subnets inbound default traffic
    #
    default_inbound = [
      {
        rule_number = 200 # Allow traffic from this vpc's private subnets
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = local.private_subnets_cidr[0]
      },
      {
        rule_number = 900 # shared pritunl vpn server
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = "${data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip}/32"
      },
      {
        rule_number = 910 # NTP traffic
        rule_action = "allow"
        from_port   = 123
        to_port     = 123
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 920 # Filter out privileged TCP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 930 # Filter out privileged UDP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 940 # HCP Vault HVN vpc
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = var.vpc_vault_hvn_cidr
      },
    ]

    #
    # Allow VPC private subnets inbound traffic
    #
    private_inbound = local.private_inbound
  }

  #
  # Data Source: Shared
  #
  shared-vpcs = {
    shared-base = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network/terraform.tfstate"
    }
  }

  #
  # Data Source: Network
  #
  network-vpcs = {
    network-base = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/network/terraform.tfstate"
    }
  }

  #
  # Data Sources
  #
  datasources-vpcs = merge(
    var.enable_tgw ? data.terraform_remote_state.network-vpcs : null, # network
    data.terraform_remote_state.shared-vpcs,                          # shared
  )
}
