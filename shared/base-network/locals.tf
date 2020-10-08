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

  private_subnets = [
    "172.18.0.0/23",
    "172.18.2.0/23",
  ]

  public_subnets = [
    "172.18.6.0/23",
    "172.18.8.0/23",
  ]
}

locals {
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
    private_inbound = [
      {
        rule_number = 100 # shared pritunl vpn server
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "${data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip}/32"
      },
      {
        rule_number = 110 # apps-devstg private subnet A
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-dev.outputs.private_subnets_cidr[0]
      },
      {
        rule_number = 120 # apps-devstg private subnet B
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-dev.outputs.private_subnets_cidr[1]
      },
      {
        rule_number = 130 # apps-devstg private subnet C
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-dev.outputs.private_subnets_cidr[2]
      },
      {
        rule_number = 140 # apps-devstg-eks private subnet A
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-dev-eks.outputs.private_subnets_cidr[0]
      },
      {
        rule_number = 150 # apps-devstg-eks private subnet B
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-dev-eks.outputs.private_subnets_cidr[1]
      },
      {
        rule_number = 160 # apps-devstg-eks private subnet C
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-dev-eks.outputs.private_subnets_cidr[2]
      },
      {
        rule_number = 170 # apps-prd private subnet A
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-prd.outputs.private_subnets_cidr[0]
      },
      {
        rule_number = 180 # apps-prd private subnet B
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-prd.outputs.private_subnets_cidr[1]
      },
      {
        rule_number = 190 # apps-prd private subnet C
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-apps-prd.outputs.private_subnets_cidr[2]
      },
    ]
  }
}
