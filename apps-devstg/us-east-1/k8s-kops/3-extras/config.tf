
#------------------------------------------------------------------------------
# Providers
#------------------------------------------------------------------------------
provider "aws" {
  region  = "ca-central-1"
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  region  = var.region
  profile = "${var.project}-shared-devops"
}

provider "kubernetes" {
  config_path    = "canada01-kops.devstg.k8s.local"
  config_context = "canada01-kops.devstg.k8s.local"
}

provider "helm" {
  kubernetes {
    config_path    = "canada01-kops.devstg.k8s.local"
    config_context = "canada01-kops.devstg.k8s.local"
  }
}

#------------------------------------------------------------------------------
# Backend Config (partial)
#------------------------------------------------------------------------------
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws        = "~> 4.10"
    kubernetes = "~> 2.11"
    helm       = "~> 2.13"
  }
  backend "s3" {
    key = "apps-devstg/ca-central-1/k8s-kops/3-extras/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-dns" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/global/dns/binbash.co/terraform.tfstate"
  }
}
