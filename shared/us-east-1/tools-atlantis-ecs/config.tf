#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 5.0"
  }

  backend "s3" {
    key = "shared/atlantis-ecs/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/dns/binbash.com.ar/terraform.tfstate"
  }
}

data "terraform_remote_state" "certs" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-certs/terraform.tfstate"
  }
}

data "aws_secretsmanager_secret_version" "atlantis" {
  secret_id = "/devops/shared/atlantis"
}
