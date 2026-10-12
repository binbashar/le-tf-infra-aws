provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = local.tags
  }
}

terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  backend "s3" {
    key = "management/github-oidc-tofu-plan/terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}
