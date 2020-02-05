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
  vpc_cidr_block = "172.18.64.0/20"
  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  private_subnets = [
    "172.18.64.0/23",
    "172.18.66.0/23",
    "172.18.68.0/23",
  ]

  public_subnets = [
    "172.18.72.0/23",
    "172.18.74.0/23",
    "172.18.76.0/23",
  ]

  #
  # K8s Kops Requisites
  #
  # We'll use a shorter environment name in order to keep things simple
  short_environment = replace(var.environment, "apps-", "")

  # The name of the K8s Kops Dev cluster
  base_domain_name = "binbash.aws"
  k8s_cluster_name = "cluster-kops-1.k8s.${local.short_environment}.${local.base_domain_name}"

  # We need these so that k8s aws cloud provider recognizes our private subnets
  # and associates them to any load balancer that is created
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.k8s_cluster_name}" : 1
    "kubernetes.io/role/internal-elb" : 1
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.k8s_cluster_name}" : 1
    "kubernetes.io/role/elb" : 1
  }
}
