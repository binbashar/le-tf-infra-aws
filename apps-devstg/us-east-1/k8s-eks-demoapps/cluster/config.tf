#
# Providers
#
provider "aws" {
  region  = var.region
  profile = var.profile
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

#
# Backend Config (partial)
#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws        = "~> 5.74"
    kubernetes = "~> 2.23"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}

#
# Data Sources
#

data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_name

  depends_on = [module.cluster]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster_name

  depends_on = [module.cluster]
}


data "terraform_remote_state" "cluster-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "cluster-identities" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks-demoapps/identities/terraform.tfstate"
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/security-keys/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}
