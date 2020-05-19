# Providers
provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
  required_version = ">= 0.11.14"

  backend "s3" {
    key = "root/cost-mgmt/terraform.tfstate"
  }
}

data "terraform_remote_state" "notifications" {
  backend = "s3"

  config {
    region  = "${var.region}"
    profile = "${var.profile}"
    bucket  = "${var.bucket}"
    key     = "${var.environment}/notifications/terraform.tfstate"
  }
}
