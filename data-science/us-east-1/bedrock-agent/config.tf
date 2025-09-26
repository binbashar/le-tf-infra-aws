#=============================
# Backend Config (partial)
#=============================
terraform {
  required_version = "~> 1.6.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.0.0"
    }
    # opensearch provider removed - not used in this configuration
  }
  backend "s3" {
    key = "data-science/us-east-1/bedrock-agent/terraform.tfstate"
  }
}

#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

# Required by the bedrock module but not used
provider "awscc" {
  region  = var.region
  profile = var.profile
}

# opensearch provider intentionally omitted; add when Knowledge Base is enabled

#=============================#
# Data sources                #
#=============================#

# Data source moved to iam.tf

data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}