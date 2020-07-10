# Providers
provider "aws" {
  version                 = "~> 2.69"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#replica provider
provider "aws" {
  version                 = "~> 2.69"
  alias                   = "region_secondary"
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

# Backend Config (partial)
terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "apps-devstg/k8s-kops/prerequisites/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc_shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-shared-devops"
    bucket  = "bb-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}
