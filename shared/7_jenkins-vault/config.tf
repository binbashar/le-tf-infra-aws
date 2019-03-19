# Providers
provider "aws" {
    region = "${var.region}"
    profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
    required_version = ">= 0.11.13"

    backend "s3" {
        key = "shared/jenkins-vault/terraform.tfstate"
    }
}

locals {
    tags = {
        Name = "infra-jenkinsvault"
        Terraform = "true"
        Environment = "${var.environment}"
    }
}

data "terraform_remote_state" "vpc" {
    backend     = "s3"
    config {
      region = "${var.region}"
      profile = "${var.profile}"
      bucket = "bb-shared-terraform-state-storage-s3"
      key    = "shared/network/terraform.tfstate"
    }
}
