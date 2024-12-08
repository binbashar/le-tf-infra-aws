locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  # Important
  # Docker runs in the 172.17.0.0/16 CIDR range in Amazon EKS clusters. We recommend that your cluster's VPC subnets do
  # not overlap this range. Otherwise, you will receive the following error:
  # Error: : error upgrading connection: error dialing backend: dial tcp 172.17.nn.nn:10250: getsockopt: no route to host
  vpc_name       = "${var.project}-${var.environment}-vpc"
  vpc_cidr_block = "172.18.0.0/20"
  azs = [
    "${var.region}a",
    "${var.region}b"
  ]

  private_subnets_cidr = ["172.18.0.0/21"]
  private_subnets = [
    "172.18.0.0/23",
    "172.18.2.0/23",
  ]

  public_subnets_cidr = ["172.18.6.0/21"]
  public_subnets = [
    "172.18.6.0/23",
    "172.18.8.0/23",
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
      {
        rule_number = 800 # own private subnet cidr
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
        rule_number = 930 # Filtering known TCP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65535
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 940 # Filtering known UDP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65535
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

  # network
  network-vpcs = {
    network-base = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/network/terraform.tfstate"
    }
  }

  # apps-devstg
  apps-devstg-vpcs = {
    apps-devstg-base = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/network/terraform.tfstate"
    }
    apps-devstg-k8s-eks = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
    }
    apps-devstg-eks-demoapps = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
    }
  }

  # apps-devstg-dr
  apps-devstg-dr-vpcs = {}

  # apps-prd
  apps-prd-vpcs = {
    apps-prd-base = {
      region  = var.region
      profile = "${var.project}-apps-prd-devops"
      bucket  = "${var.project}-apps-prd-terraform-backend"
      key     = "apps-prd/network/terraform.tfstate"
    }
  }

  # apps-prd-dr
  apps-prd-dr-vpcs = {}

  # shared-dr
  shared-dr-vpcs = {
    shared-dr-base = {
      region  = var.region
      profile = var.profile
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network-dr/terraform.tfstate"
    }
  }

  # security
  security-vpcs = {
    security-base = {
      region  = var.region
      profile = "${var.project}-security-devops"
      bucket  = "${var.project}-security-terraform-backend"
      key     = "security/network/terraform.tfstate"
    }
  }

    # data-science
  data-science-vpcs = {
    data-science-base = {
      region  = var.region
      profile = "${var.project}-data-science-devops"
      bucket  = "${var.project}-data-science-terraform-backend"
      key     = "data-science/network/terraform.tfstate"
    }
  }

  datasources-vpcs = merge(
    var.enable_tgw ? data.terraform_remote_state.network-vpcs : null, # network
    data.terraform_remote_state.apps-devstg-vpcs,                     # apps-devstg-vpcs
    data.terraform_remote_state.apps-devstg-dr-vpcs,                  # apps-devstg-dr-vpcs
    data.terraform_remote_state.apps-prd-vpcs,                        # apps-prd-vpcs
    data.terraform_remote_state.apps-prd-dr-vpcs,                     # apps-prd-dr-vpcs
    data.terraform_remote_state.security-vpcs,                        # security-vpcs
    data.terraform_remote_state.data-science-vpcs,                    # data-science-vpcs
  )
}
