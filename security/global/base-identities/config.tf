#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = local.tags
  }
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "security/identities/terraform.tfstate"
  }
}

data "terraform_remote_state" "apps-devstg-keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/security-keys/terraform.tfstate"
  }
}

#
# Uncomment if you like to deploy and test /apps-devtg/storage/bucket-demo-files layer
#
/*data "terraform_remote_state" "apps-devstg-storage-bucket-demo-files" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/storage-bucket-demo-files/terraform.tfstate"
  }
}*/
