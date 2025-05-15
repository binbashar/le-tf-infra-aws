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

provider "mysql" {
  endpoint = module.demoapps.cluster_endpoint
  username = module.demoapps.cluster_master_username
  password = module.demoapps.cluster_master_password
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.2"

  required_providers {
    aws   = "~> 4.12"
    mysql = {
      source  = "winebarrel/mysql"
      version = "1.10.6"
    }
  }

  backend "s3" {
    key = "apps-devstg/databases-aurora/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "eks_vpc_demoapps" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/k8s-eks-demoapps/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared_vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}

#
# Note: for the sake of simplicity we are storing the db admin credentials
#       under the same path of a demoapp. In other words, demoapps will use
#       use admin credentials for talking to the db. Later on, we will have
#       to store admin credentials under a separate path and create separate,
#       more restrictied credentials for demoapps.
#
data "aws_secretsmanager_secret_version" "databases_aurora" {
  provider  = aws.shared
  secret_id = "/devops/apps-devstg/database-aurora/administrator"
}