#=============================#
# AWS Provider Settings       #
#=============================#

provider "aws" {
  region = var.region_primary
  profile = "bb-shared-devops"
}

provider "aws" {
  alias   = "accounts"
  for_each = local.account_settings
  region  = each.value.region
  profile = each.value.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = "~> 4.10"
  }

  # Backend commented out to avoid initialization prompts
  # Uncomment and configure when ready to use S3 backend
  backend "s3" {
    key = "baseline/security-base/terraform.tfstate"
  }
}
