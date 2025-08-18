#=============================
# Backend Config (partial)
#=============================
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = "~> 5.0"
    awscc = "~> 1.0"
    archive = "~> 2.0"
  }

  backend "s3" {
    key = "data-science/bedrock-kyb-agent/terraform.tfstate"
  }
}

#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "awscc" {
  region  = var.region
  profile = var.profile
}

#=============================#
# Data sources                #
#=============================#

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}