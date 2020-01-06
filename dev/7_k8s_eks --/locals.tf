locals {
  cluster_name = "${var.project}-${var.environment}-eks-${random_string.suffix.result}"

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  # Important
  # Docker runs in the 172.17.0.0/16 CIDR range in Amazon EKS clusters. We recommend that your cluster's VPC subnets do
  # not overlap this range. Otherwise, you will receive the following error:
  # Error: : error upgrading connection: error dialing backend: dial tcp 172.17.nn.nn:10250: getsockopt: no route to host
  vpc_name       = "${var.project}-${var.environment}-vpc-eks"
  vpc_cidr_block = "172.18.0.0/20"
  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c",
  ]

  private_subnets = [
    "172.18.0.0/23",
    "172.18.2.0/23",
    "172.18.4.0/23",
  ]

  public_subnets = [
    "172.18.6.0/23",
    "172.18.8.0/23",
    "172.18.10.0/23",
  ]

  mgmt_worker_subnets = [
    "172.17.0.0/16",
    "172.18.0.0/16",
  ]

  tags = {
    Terraform                                     = "true"
    Environment                                   = var.environment
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