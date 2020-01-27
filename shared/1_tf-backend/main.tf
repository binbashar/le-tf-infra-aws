terraform {
  required_version = ">= 0.12.18"
}

variable "region" {}
variable "profile" {}
variable "project" {}
variable "environment" {}
variable "encrypt" {}
variable "dynamodb_table" {}

provider "aws" {
  version = "~> 2.43"
  region  = var.region
  profile = var.profile
}

provider "null" {
  version = "~> 2.1"
}

module "terraform_backend" {
  source = "git::git@github.com:binbashar/terraform-aws-tfstate-backend.git?ref=v1.0.3"

  #
  # Bucket Name and Region
  #
  region    = var.region
  delimiter = "-"
  namespace = var.project
  stage     = var.environment
  name      = "terraform-state-storage-s3"

  #
  # Security
  #
  acl                           = "private"
  block_public_acls             = true
  block_public_policy           = true
  restrict_public_buckets       = true
  enable_server_side_encryption = var.encrypt

  #
  # Replication
  #
  bucket_replication_enabled = true
  bucket_replication_region  = "us-east-2"
  bucket_replication_profile = var.profile

  tags = local.tags
}
