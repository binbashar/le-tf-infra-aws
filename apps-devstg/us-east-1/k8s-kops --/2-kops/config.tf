# Variables
variable "profile" {
  description = "AWS Profile"
}

variable "region" {
  description = "AWS Region"
}

# AWS Provider
provider "aws" {
  region  = "ca-central-1"
  profile = var.profile
}

provider "aws" {
  alias   = "files"
  region  = "ca-central-1"
  profile = var.profile
}

# Backend Config (partial)
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 5.0"
  }

  backend "s3" {
    key = "apps-devstg/ca-central-1/k8s-kops/2-kops/terraform.tfstate"
  }
}
