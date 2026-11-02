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

# The account that hosts the sending domain's public DNS zone.
# In a client installation, point this at wherever their zone lives.
provider "aws" {
  alias   = "dns"
  region  = var.region
  profile = "${var.project}-shared-devops"

  default_tags {
    tags = local.tags
  }
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key = "management/cost-email-report/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# The sending domain's public zone (binbash.com.ar, in the shared account).
# Not read when manage_dns_records = false, so an installation without access
# to that state can still create the identity and get the dkim_records output.
#
data "terraform_remote_state" "dns" {
  count   = var.manage_dns_records ? 1 : 0
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}
