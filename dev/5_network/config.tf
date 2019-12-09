# Providers
provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
  required_version = ">= 0.11.14"

  backend "s3" {
    key = "dev/network/terraform.tfstate"
  }
}

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-eks" {
  backend = "s3"

  config {
    region  = "${var.region}"
    profile = "${var.profile}"
    bucket  = "bb-dev-terraform-state-storage-s3"
    key     = "dev/k8s-eks/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config {
    region  = "${var.region}"
    profile = "bb-shared-devops"
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/network/terraform.tfstate"
  }
}

