# -------------------------------------
# Providers
# -------------------------------------
provider "aws" {
  region  = var.region
  profile = var.profile
}

# -------------------------------------
# Backend Config (partial)
# -------------------------------------
terraform {
  required_version = ">= 0.14.4"

  backend "s3" {
    key = "apps-devstg/databases-aurora/rds-export-to-s3/terraform.tfstate"
  }

  required_providers {
    aws = ">= 3.8"
  }
}

# -------------------------------------
# Data Resources
# -------------------------------------
data "terraform_remote_state" "databases-aurora" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/databases-aurora/terraform.tfstate"
  }
}
