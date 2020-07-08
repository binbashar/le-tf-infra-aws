# Variables
variable "profile" {
  description = "AWS Profile"
}

variable "region" {
  description = "AWS Region"
}

# AWS Provider
provider "aws" {
  version = "~> 2.69"
  region  = "${var.region}"
  profile = "${var.profile}"
  shared_credentials_file = "~/.aws/bb-le/config"
}

# Backend Config (partial)
terraform {
  required_version = "= 0.11.14"

  backend "s3" {
    key = "apps-devstg/k8s-kops/terraform.tfstate"
  }
}
