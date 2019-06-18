# Providers
provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
  required_version = ">= 0.11.14"

  backend "s3" {
    key = "shared/vpn/terraform.tfstate"
  }
}

locals {
  tags = {
    Name        = "infra-openvpn"
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region  = "${var.region}"
    profile = "${var.profile}"
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config {
    region  = "${var.region}"
    profile = "${var.profile}"
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/security/terraform.tfstate"
  }
}
