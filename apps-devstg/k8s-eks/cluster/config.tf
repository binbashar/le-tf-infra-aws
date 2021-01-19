#
# Providers
#
provider "aws" {
  version                 = "~> 3.2"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.13"
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "apps-devstg/k8s-eks/cluster/terraform.tfstate"
  }
}

#
# Data Sources
#
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "terraform_remote_state" "shared-eks-vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
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
