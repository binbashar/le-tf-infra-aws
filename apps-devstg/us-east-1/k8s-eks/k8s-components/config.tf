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

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 1.1.3"

  required_providers {
    aws        = "~> 4.10"
    helm       = "~> 2.5"
    kubernetes = "~> 2.10"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks/k8s-components/terraform.tfstate"
  }
}

#
# Data Sources
#

# Get the current Account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region configured in the provider
data "aws_region" "current" {}

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

data "terraform_remote_state" "eks-identities" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks/identities/terraform.tfstate"
  }
}

data "terraform_remote_state" "certs" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/security-certs/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-dns" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-container-registry" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/container-registry/terraform.tfstate"
  }
}
