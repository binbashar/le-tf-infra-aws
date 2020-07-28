locals {
  cluster_name = "${var.project}-${var.environment}-eks-${random_string.suffix.result}"

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  # Important
  # Docker runs in the 172.17.0.0/16 CIDR range in Amazon EKS clusters. We recommend that your cluster's VPC subnets do
  # not overlap this range. Otherwise, you will receive the following error:
  # Error: : error upgrading connection: error dialing backend: dial tcp 172.17.nn.nn:10250: getsockopt: no route to host
  vpc_name       = "${var.project}-${var.environment}-vpc-eks"
  vpc_cidr_block = "172.19.0.0/20"
  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c",
  ]

  private_subnets = [
    "172.19.0.0/23",
    "172.19.2.0/23",
    "172.19.4.0/23",
  ]

  public_subnets = [
    "172.19.6.0/23",
    "172.19.8.0/23",
    "172.19.10.0/23",
  ]

  mgmt_worker_subnets = [
    "172.18.0.0/20",
    "172.18.32.0/20",
    "172.19.0.0/20",
  ]

  tags = {
    Terraform                                     = "true"
    Environment                                   = var.environment
    GithubRepo                                    = "terraform-aws-vpc"
    GithubOrg                                     = "binbashar"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
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

resource "random_string" "suffix" {
  length  = 8
  special = false
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
        rule_number = 110 # shared private subnet A
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-shared.outputs.private_subnets_cidr[0]
      },
      {
        rule_number = 120 # shared private subnet B
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = data.terraform_remote_state.vpc-shared.outputs.private_subnets_cidr[1]
      },
    ]
  }
}
