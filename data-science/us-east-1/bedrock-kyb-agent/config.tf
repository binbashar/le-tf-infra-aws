terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    key = "data-science/us-east-1/bedrock-kyb-agent/terraform.tfstate"
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "awscc" {
  region  = var.region
  profile = var.profile
}

data "aws_caller_identity" "current" {}