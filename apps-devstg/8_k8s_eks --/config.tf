#
# Providers
#
# AWS
#
provider "aws" {
  region  = var.region
  profile = var.profile
  version = ">= 2.40"
}

#
# Kubernetes
#
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10"
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.12.19"

  backend "s3" {
    key = "dev/k8s-eks/terraform.tfstate"
  }
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-eks" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = "bb-dev-terraform-state-storage-s3"
    key     = "dev/k8s-eks/prerequisites/terraform.tfstate"
  }
}
