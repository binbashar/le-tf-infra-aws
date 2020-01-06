#
# Providers
#
provider "aws" {
  region  = var.region
  profile = var.profile
  version = ">= 2.38"
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.12.18"

  backend "s3" {
    key = "dev/k8s-eks/terraform.tfstate"
  }
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}