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
  required_version = ">= 1.2.7"

  required_providers {
    aws   = "~> 4.40.0"
    vault = "~> 2.18.0"
  }

  backend "s3" {
    key = "security/security-monitoring/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for security
#
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}

data "aws_secretsmanager_secret_version" "monitoring_security" {
  provider  = aws.shared
  secret_id = "/devops/notifications/slack/security"
}
