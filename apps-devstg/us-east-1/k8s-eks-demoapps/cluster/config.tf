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
  required_version = "~> 1.2"

  required_providers {
    aws        = "~> 5.24"
    kubernetes = "~> 2.23"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}

#
# Data Sources
#

#
# NOTE: if you find issue with this resource while trying to stand up a cluster
#       then try commenting this block and the above kubernetes provider block.
# NOTE: if you get an error with the creation of aws-auth configmap, try 
#       running the apply command again; or, if the resource already exists,
#       then try removing it from the Terraform state and then run apply.
#
data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster_name
}

data "terraform_remote_state" "cluster-vpc" {
  backend = "s3"
  config  = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "cluster-identities" {
  backend = "s3"
  config  = {
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
  config  = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}
