# Providers
provider "aws" {
    region = var.region
    profile = var.profile
}

#replica provider
provider "aws" {
    alias  = "secondary_region"
    region = var.secondary_region
    profile = var.profile
}


# Backend Config (partial)
terraform {
    required_version = ">= 0.12.18"

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

data "terraform_remote_state" "shared_vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/network/terraform.tfstate"
  }
}