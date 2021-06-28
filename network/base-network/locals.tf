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
  vpc_cidr_block = "172.20.0.0/20"
  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  private_subnets = [
    "172.20.0.0/23",
    "172.20.2.0/23",
    "172.20.4.0/23",
  ]

  public_subnets = [
    "172.20.6.0/23",
    "172.20.8.0/23",
    "172.20.10.0/23",
  ]
}

locals {

  # Fixed private inbounds
  fixed_private_inbound = [
    {
      rule_number = 10 # shared pritunl vpn server
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      cidr_block  = "${data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip}/32"
    },
    {
      rule_number = 20 # vault hvn vpc
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      cidr_block  = var.vpc_vault_hvn_cird
    },
  ]

  # Dynamic private inbounds
  dynamic_private_inbound = flatten([
    for index, state in data.terraform_remote_state.vpc-apps : [
      for i in range(length(state.outputs.private_subnets_cidr)) :
      {
        rule_number = 100 * (index(keys(data.terraform_remote_state.vpc-apps), index) + 1) + 10 * i # apps private subnet A,B,C
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = state.outputs.private_subnets_cidr[i]
      }
    ]
  ])
  private_inbound = concat(local.fixed_private_inbound, local.dynamic_private_inbound)

  network_acls = {
    #
    # Allow / Deny VPC private subnets inbound default traffic
    #
    default_inbound = [
      {
        rule_number = 900 # NTP traffic
        rule_action = "allow"
        from_port   = 123
        to_port     = 123
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 910 # Fltering known TCP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 920 # Fltering known UDP ports (0-1024)
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
  data_vpcs = {
    #    vpc-apps-dev = {
    #  region  = var.region
    #  profile = "${var.project}-apps-devstg-devops"
    #  bucket  = "${var.project}-apps-devstg-terraform-backend"
    #  key     = "apps-devstg/network/terraform.tfstate"
    #}
    #vpc-apps-dev-eks = {
    #  region  = var.region
    #  profile = "${var.project}-apps-devstg-devops"
    #  bucket  = "${var.project}-apps-devstg-terraform-backend"
    #  key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
    #}
    #vpc-apps-dev-eks-demoapps = {
    #  region  = var.region
    #  profile = "${var.project}-apps-devstg-devops"
    #  bucket  = "${var.project}-apps-devstg-terraform-backend"
    #  key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
    #}
    vpc-apps-prd = {
      region  = var.region
      profile = "${var.project}-apps-prd-devops"
      bucket  = "${var.project}-apps-prd-terraform-backend"
      key     = "apps-prd/network/terraform.tfstate"
    }
  }
}
