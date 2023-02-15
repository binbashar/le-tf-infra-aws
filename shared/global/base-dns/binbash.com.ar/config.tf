#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
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
  required_version = "~> 1.3"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-devstg" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-devstg-eks" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns-apps-devstg-eks-v117" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks-v1.17/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-devstg-eks-demoapps" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
  }
}



data "terraform_remote_state" "vpc-apps-devstg-eks-dr" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks-dr/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-devstg-certificates" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/certificates/terraform.tfstate"
  }
}

data "terraform_remote_state" "ec2-fleet-ansible" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/ec2-fleet-ansible/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-prd" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-prd-devops"
    bucket  = "${var.project}-apps-prd-terraform-backend"
    key     = "apps-prd/network/terraform.tfstate"
  }
}
