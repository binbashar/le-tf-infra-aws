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
  vpc_cidr_block = "172.18.16.0/20"
  azs = [
    "${var.region_secondary}a",
    "${var.region_secondary}b"
  ]

  private_subnets_cidr = ["172.18.16.0/21"]
  private_subnets = [
    "172.18.16.0/23",
    "172.18.18.0/23",
    # "172.18.20.0/23",
    # "172.18.22.0/23",
  ]

  public_subnets_cidr = ["172.18.24.0/21"]
  public_subnets = [
    "172.18.24.0/23",
    "172.18.26.0/23",
    # "172.18.28.0/23",
    # "172.18.30.0/23",
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

  #
  # Data source definitions
  #
  apps-devstg-vpcs = {
    apps-devstg-k8s-eks-dr = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-dr/network/terraform.tfstate"
      tgw     = false
    }
  }
  apps-prd-vpcs = {}

  datasources-vpcs = merge(
    data.terraform_remote_state.apps-devstg-vpcs,
    data.terraform_remote_state.apps-prd-vpcs,
  )
}
