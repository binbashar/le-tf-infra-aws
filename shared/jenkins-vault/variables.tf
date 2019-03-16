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

variable "environment" {
    description = "Environment Name"
}

variable "bucket" {}

#
# External Accounts Data
#
variable "dev_account_id" {
    description = "Dev/Stage Account ID"
}
variable "appsprd_account_id" {
    description = "Production Account ID"
}
variable "security_account_id" {
    description = "Account: Security & Users Management"
}
variable "shared_account_id" {
    description = "Account: Shared Resources"
}
