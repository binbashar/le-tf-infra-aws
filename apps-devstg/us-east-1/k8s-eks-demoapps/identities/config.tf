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

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.1.3"

  required_providers {
    aws = "~> 4.11.0"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/identities/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "apps-devstg-eks-demoapps-cluster" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}
