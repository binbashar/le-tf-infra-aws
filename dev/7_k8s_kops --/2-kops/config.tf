# Variables
variable "profile" {
    description = "AWS Profile"
}
variable "region" {
    description = "AWS Region"
}

# AWS Provider
provider "aws" {
    region = "${var.region}"
    profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
    required_version = ">= 0.12.6"

    backend "s3" {
        key = "apps-devstg/k8s/kops/terraform.tfstate"
    }
}