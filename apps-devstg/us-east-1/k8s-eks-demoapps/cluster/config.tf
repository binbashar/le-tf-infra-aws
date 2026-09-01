#
# Providers
#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#
# Backend Config (partial)
#
terraform {
  required_version = "~> 1.6"

  required_providers {
    # terraform-aws-eks v21 requires the AWS provider >= 6.59.
    aws = "~> 6.59"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}

#
# Data Sources
#

# The `kubernetes` provider used to live here purely to feed the `aws-auth`
# submodule, which v21 removed. This layer holds no `kubernetes_*` resources, so
# the provider -- and the `aws_eks_cluster_auth` token data source that fed it --
# are gone. A useful side effect: applying this layer no longer touches the
# (private) Kubernetes API, so it no longer needs VPN access. Cluster access is
# granted through EKS access entries instead; see `locals.tf`.

# Resolves the IAM Identity Center DevOps permission set role, whose name suffix
# is generated and changes whenever the permission set is recreated. See
# `local.sso_devops_role_arn`.
data "aws_iam_roles" "sso_devops" {
  name_regex  = "AWSReservedSSO_DevOps_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
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
