#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "secondary_region"
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/bb/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.0.9"

  required_providers {
    aws = "~> 3.2"
  }

  backend "s3" {
    key = "apps-devstg/storage-bucket-demo-files/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}

data "terraform_remote_state" "keys-dr" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys-dr/terraform.tfstate"
  }
}


data "terraform_remote_state" "security-identities" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-security-devops"
    bucket  = "${var.project}-security-terraform-backend"
    key     = "security/identities/terraform.tfstate"
  }
}

