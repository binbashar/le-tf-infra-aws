#
# Providers
#
provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "kubernetes" {
  #### EKS
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.14.4"

  required_providers {
    aws        = "~> 3.28"
    kubernetes = "~> 2.0.2"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks/k8s-resources/terraform.tfstate"
  }
}

#
# Data Sources
#
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks-cluster.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks-cluster.outputs.cluster_id
}

data "terraform_remote_state" "eks-cluster" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks/cluster/terraform.tfstate"
  }
}
