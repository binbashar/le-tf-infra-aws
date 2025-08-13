#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  alias   = "by_region"
  for_each = local.accounts_settings
  region  = each.key
  
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.10.0"

  required_providers {
    aws = "~> 4.10"
  }

  # Backend commented out to avoid initialization prompts
  # Uncomment and configure when ready to use S3 backend
  #backend "s3" {
  #  key = "baseline/${local.account_name}/security-base/terraform.tfstate"
  #}
}
