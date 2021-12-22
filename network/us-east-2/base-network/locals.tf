locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  vpc_name       = "${var.project}-${var.environment}-dr-vpc"
  vpc_cidr_block = "172.20.32.0/20"
  azs = [
    "${var.region_secondary}a",
    "${var.region_secondary}b",
  ]

  private_subnets_cidr = ["172.20.32.0/21"]
  private_subnets = [
    "172.20.32.0/23",
    "172.20.34.0/23",
  ]

  public_subnets_cidr = ["172.20.40.0/21"]
  public_subnets = [
    "172.20.40.0/23",
    "172.20.42.0/23",
  ]
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
      #{
      #  rule_number = 900 # shared pritunl vpn server
      #  rule_action = "allow"
      #  from_port   = 0
      #  to_port     = 65535
      #  protocol    = "all"
      #  cidr_block  = "${data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip}/32"
      #},
      {
        rule_number = 910 # vault hvn vpc
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = var.vpc_vault_hvn_cird
      },
      {
        rule_number = 920 # NTP traffic
        rule_action = "allow"
        from_port   = 123
        to_port     = 123
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 930 # Fltering known TCP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 940 # Fltering known UDP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
    ]

    #
    # Allow VPC private subnets inbound traffic
    #
    private_inbound = local.private_inbound
  }

  # Data source definitions
  #

  # shared-dr
  shared-dr-vpcs = {
    shared-dr-base = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network-dr/terraform.tfstate"
    }
  }

  # network-dr
  network-dr-vpcs = {
    network-firewall-dr = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/network-firewall-dr/terraform.tfstate"
    }
  }

  # apps-devstg-dr
  apps-devstg-dr-vpcs = {
    apps-devstg-k8s-eks-dr = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-dr/network/terraform.tfstate"
    }
  }

  # apps-prd-dr
  apps-prd-dr-vpcs = {}

  datasources-vpcs = merge(
    data.terraform_remote_state.network-dr-vpcs,     # network-dr
    data.terraform_remote_state.shared-dr-vpcs,      # shared-dr
    data.terraform_remote_state.apps-devstg-dr-vpcs, # apps-devstg-dr
    data.terraform_remote_state.apps-prd-dr-vpcs,    # apps-prd-dr
  )
}

locals {
  cgws = { for k, v in local.customer_gateways :
    k => {
      bgp_asn    = v["bgp_asn"]
      ip_address = v["ip_address"]
    }
  }

  vpn_static_routes = flatten([for k, v in local.customer_gateways :
    [for r in lookup(v, "static_routes", []) :
      {
        cgw   = k
        route = r
      }
    ]
  ])
}
