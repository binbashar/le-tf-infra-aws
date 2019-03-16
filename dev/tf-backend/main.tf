terraform {
    required_version = ">= 0.11.6"
}

variable "region" {}
variable "profile" {}
variable "bucket" {}
variable "dynamodb_table" {}

provider "aws" {
    version = "~> 1.0"
    region = "${var.region}"
    profile = "${var.profile}"
}

module "dev_terraform_backend" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/terraform-backend?ref=v0.2"

    bucket_name = "${var.bucket}"
    bucket_description = "S3 Bucket for Applications dev Terraform Remote State Storage"
    table_name = "${var.dynamodb_table}"
    table_description = "DynamoDB for Applications dev Terraform Remote State Locking"
    replication_region = "us-east-2"
    replication_profile = "${var.profile}"
}