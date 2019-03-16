# Providers
provider "aws" {
    region = "${var.region}"
    profile = "${var.profile}"
}

# Backend Config (partial)
terraform {
    required_version = ">= 0.11.6"

    backend "s3" {
        key = "dev/secrets/terraform.tfstate"
    }
}