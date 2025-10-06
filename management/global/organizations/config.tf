#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  region  = var.region
  profile = "${var.project}-shared-devops"
}

provider "aws" {
  alias   = "network"
  region  = var.region
  profile = "${var.project}-network-devops"
}

provider "aws" {
  alias   = "apps-devstg"
  region  = var.region
  profile = "${var.project}-apps-devstg-devops"
}

provider "aws" {
  alias   = "apps-prd"
  region  = var.region
  profile = "${var.project}-apps-prd-devops"
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
    key = "management/organizations/terraform.tfstate"
  }
}
