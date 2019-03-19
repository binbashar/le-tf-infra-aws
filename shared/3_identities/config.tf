# Providers
provider "aws" {
    region = "${var.region}"
    profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
    required_version = ">= 0.11.13"

    backend "s3" {
        key = "shared/identities/terraform.tfstate"
    }
}