#
# Providers
#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  region  = var.region
  profile = "${var.project}-shared-devops"
}

#
# Backend Config (partial)
#
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = "~> 5.20"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-training/network/terraform.tfstate"
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

