#=============================
# Backend Config (partial)
#=============================
terraform {
  required_version = ">= 1.6.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
  backend "s3" {
    key = "data-science/us-east-1/bedrock-agentcore/terraform.tfstate"
  }
}

#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "awscc" {
  region  = var.region
  profile = var.profile
}
