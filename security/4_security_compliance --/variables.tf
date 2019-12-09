#===========================================#
# AWS Provider Settings                     #
#===========================================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#===========================================#
# Project Variables                         #
#===========================================#
variable "project" {
  description = "Project Name"
}

variable "project_long" {
  description = "Project Name Complete"
}

variable "environment" {
  description = "Environment Name"
}

variable "security_account_id" {}
variable "shared_account_id" {}
variable "dev_account_id" {}

variable "bucket" {}
variable "dynamodb_table" {}
variable "encrypt" {}