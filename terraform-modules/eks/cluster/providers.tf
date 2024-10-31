
terraform {
  required_providers {
    kubernetes = "~> 2.27"
  }
}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)
  #token                  = data.aws_eks_cluster_auth.cluster.token
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      "${element(split("/", module.cluster.cluster_arn),length(split("/", module.cluster.cluster_arn))-1)}",
      "--region",
      var.region,
      "--profile",
      var.profile
    ]
    command     = "aws"
  }
}
#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#  token                  = data.aws_eks_cluster_auth.cluster.token
#}
#data "aws_eks_cluster" "cluster" {
#  name = module.cluster.cluster_id
#
#}
#
#data "aws_eks_cluster_auth" "cluster" {
#  name = module.cluster.cluster_id
#
#}
