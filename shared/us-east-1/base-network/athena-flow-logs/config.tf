# -------------------------------------
# Providers
# -------------------------------------
provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

# -------------------------------------
# Backend Config (partial)
# -------------------------------------
terraform {
  required_version = ">= 0.14.4"

  backend "s3" {
    key = "shared/network/athena-flow-logs/terraform.tfstate"
  }

  required_providers {
    aws = ">= 3.8"
  }
}
