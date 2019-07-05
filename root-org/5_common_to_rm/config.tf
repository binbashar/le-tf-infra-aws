# Providers
provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
  required_version = ">= 0.11.14"

  backend "s3" {
    key = "root-org/common/terraform.tfstate"
  }
}

//data "terraform_remote_state" "sns" {
//  backend = "s3"
//
//  config {
//    region  = "${var.region}"
//    profile = "${var.profile}"
//    bucket  = "bb-root-org-terraform-state-storage-s3"
//    key     = "root-org/notifications/terraform.tfstate"
//  }
//}