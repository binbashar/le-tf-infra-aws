# Providers
provider "aws" {
  version = "~> 2.40"
  region  = var.region
  profile = var.profile
}

#replica provider
provider "aws" {
  version = "~> 2.40"
  alias   = "region_secondary"
  region  = var.region_secondary
  profile = var.profile
}

# Backend Config (partial)
terraform {
  required_version = ">= 0.12.19"

  backend "s3" {
    key = "dev/k8s-kops/prerequisites/terraform.tfstate"
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
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/network/terraform.tfstate"
  }
}
