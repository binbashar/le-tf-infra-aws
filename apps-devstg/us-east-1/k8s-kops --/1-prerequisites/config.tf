# Providers
provider "aws" {
  region  = var.region_primary
  profile = var.profile
}

#replica provider
provider "aws" {
  alias   = "region_secondary"
  region  = var.region_secondary
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  region  = var.region
  profile = "${var.project}-shared-devops"
}

# Backend Config (partial)
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 5.0"
  }

  backend "s3" {
    key = "apps-devstg/ca-central-1/k8s-kops/1-prerequisites/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/ca-central-1/kops-network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/us-east-1/network/terraform.tfstate"
  }
}
