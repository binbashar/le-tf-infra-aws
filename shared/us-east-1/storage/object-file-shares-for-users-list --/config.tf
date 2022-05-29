#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region
  profile                 = var.profile
}

provider "aws" {
  alias                   = "security"
  region                  = var.region
  profile                 = "${var.project}-security-devops"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.0.9"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "shared/storage/object-file-shares/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}
