#------------------------------------------------------------------------------
# Providers
#------------------------------------------------------------------------------
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

#------------------------------------------------------------------------------
# Backend Config (partial)
#------------------------------------------------------------------------------
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws        = "~> 5.0"
    kubernetes = "~> 2.23"
    helm       = "~> 2.11"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/k8s-workloads/terraform.tfstate"
  }
}

##------------------------------------------------------------------------------
# Data Sources
##------------------------------------------------------------------------------
# Get the current Account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region configured in the provider
data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.cluster.outputs.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.cluster.outputs.cluster_name
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}
