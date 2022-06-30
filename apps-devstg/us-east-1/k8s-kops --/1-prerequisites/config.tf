# Providers
provider "aws" {
  version = "~> 3.0"
  region  = var.region
  profile = var.profile
}

#replica provider
provider "aws" {
  version = "~> 3.0"
  alias   = "region_secondary"
  region  = var.region_secondary
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  version = "~> 3.2"
  region  = var.region
  profile = "${var.project}-shared-devops"
}

# Backend Config (partial)
terraform {
  required_version = ">= 0.13.2"

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

data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}
