#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  region                  = var.region
  alias                   = "primary"
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.0.9"

  required_providers {
    aws = "~> 3.0"
  }

  backend "s3" {
    key = "security/security-audit-dr/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#
# Config  (security-audit)
#
data "terraform_remote_state" "config" {
  count   = var.enable_config_bucket_replication ? 1 : 0
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-compliance/terraform.tfstate"
  }
}

