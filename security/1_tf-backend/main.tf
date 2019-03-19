terraform {
    required_version = ">= 0.11.13"
}

variable "region" {}
variable "profile" {}
variable "bucket" {}
variable "dynamodb_table" {}

provider "aws" {
    version = "~> 2.0"
    region = "${var.region}"
    profile = "${var.profile}"
}

module "security_terraform_backend" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/terraform-backend?ref=v0.3"

    bucket_name = "${var.bucket}"
    bucket_description = "S3 Bucket for ${var.profile} Terraform Remote State Storage"
    table_name = "${var.dynamodb_table}"
    table_description = "DynamoDB for ${var.profile} Terraform Remote State Locking"
    replication_region = "us-east-2"
    replication_profile = "${var.profile}"
}