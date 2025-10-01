#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region_secondary
  profile = var.profile
}

provider "aws" {
  region  = var.region
  alias   = "primary"
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.3"

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
# CloudTrail (security-audit)
#
data "terraform_remote_state" "cloudtrail" {
  count   = var.enable_cloudtrail_bucket_replication ? 1 : 0
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-audit/terraform.tfstate"
  }
}
