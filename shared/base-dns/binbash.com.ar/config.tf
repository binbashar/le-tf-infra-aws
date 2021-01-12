#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 3.2"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "apps-devstg"
  version                 = "~> 3.2"
  region                  = var.region
  profile                 = "${var.project}-apps-devstg-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "apps-prd"
  version                 = "~> 3.2"
  region                  = var.region
  profile                 = "${var.project}-apps-prd-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.28"

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

data "terraform_remote_state" "dns-apps-devstg-kops" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-kops/prerequisites/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-devstg-eks" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks/vpc/terraform.tfstate"
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
