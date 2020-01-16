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
  description = "Project Long Name"
}

variable "environment" {
  description = "Environment Name"
}

#===========================================#
# Accounts                                  #
#===========================================#
variable "security_account_id" {}
variable "shared_account_id" {}
variable "dev_account_id" {}

variable "bucket" {}
variable "encrypt" {}

variable "cloudtrail_org_bucket" {}