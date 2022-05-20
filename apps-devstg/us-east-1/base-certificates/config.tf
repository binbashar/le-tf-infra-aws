#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  # comment this 2 lines for aws sso enable
  # shared_credentials_files = ["~/.aws/${var.project}/credentials"]
  # shared_config_files      = ["~/.aws/${var.project}/config"]

}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~>1.0"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "apps-devstg/certificates/terraform.tfstate"
  }
}
