#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

# binbash-shared route53 cross-account SES DNS validation
provider "aws" {
  region  = var.region
  profile = "${var.project}-shared-devops"
  alias   = "shared-route53"
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
    key = "apps-prd/app-ai-lab/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for dns
#
data "terraform_remote_state" "dns-binbash-co" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.co/terraform.tfstate"
  }
}
