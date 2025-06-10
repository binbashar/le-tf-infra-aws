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
  required_version = "~> 1.2"

  required_providers {
    aws   = "~> 4.10"
  }

  backend "s3" {
    key = "apps-prd/notifications/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}

data "aws_secretsmanager_secret_version" "slack_hook_url_monitoring" {
  provider  = aws.shared
  secret_id = "/devops/notifications/slack/monitoring"
}

data "aws_secretsmanager_secret_version" "slack_hook_url_monitoring_security" {
  provider  = aws.shared
  secret_id = "/devops/notifications/slack/security"
}
