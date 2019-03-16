#
# AWS Provider Settings
#
variable "region" {
    description = "AWS Region"
}
variable "profile" {
    description = "AWS Profile"
}

#
# Project Variables
#
variable "project" {
    description = "Project Name"
}
variable "environment" {
    description = "Environment Name"
}
variable "security_account_id" {
    description = "ID account for dev aws"
}

# AWS Config

variable "bucket_prefix" {
  default = "config"
}

variable "bucket_key_prefix" {
  default = "config"
}

variable "sns_topic_arn" {
  default = ""
}

variable "tags" {
  default = {
    "owner"   = "bb-security-account"
    "project" = "bb-config-security"
    "client"  = "bb-internal"
  }
}
