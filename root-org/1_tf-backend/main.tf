terraform {
  required_version = ">= 0.11.14"
}

variable "region" {}
variable "profile" {}
variable "bucket" {}
variable "dynamodb_table" {}

provider "aws" {
  version = "~> 2.15"
  region  = "${var.region}"
  profile = "${var.profile}"
}

provider "null" {
  version = "~> 2.1"
}

module "terraform_backend" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/terraform-backend?ref=v0.6"

  bucket_name         = "${var.bucket}"
  bucket_description  = "S3 Bucket for ${var.profile} Terraform Remote State Storage"
  table_name          = "${var.dynamodb_table}"
  table_description   = "DynamoDB for ${var.profile} Terraform Remote State Locking"
  replication_region  = "us-east-2"
  replication_profile = "${var.profile}"
}
