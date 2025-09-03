#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  alias   = "accounts"
  for_each = local.account_settings
  region  = each.value.region
  shared_credentials_files = ["~/.aws/bb/credentials"]
  shared_config_files = ["~/.aws/bb/config"]

  profile = each.value.profile
  
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
