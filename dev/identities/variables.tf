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

#
# External Accounts Data
#
variable "security_account_id" {
    description = "Security & Users Management Account ID"
}
variable "shared_account_id" {
    description = "Shared Resources Account ID"
}
variable "shared_vpc_id" {
    description = "VPC ID of Shared Resources Account"
}
variable "shared_vpc_cidr_block" {
    description = "VPC CIDR Block of Shared Resources Account"
}

variable "dev_account_id" {
    description = "ID account for dev aws"
}

variable "tags" {
  default = {
    "owner"   = "bb-dev-account"
    "project" = "bb-config-dev"
    "client"  = "bb-internal"
  }
}
