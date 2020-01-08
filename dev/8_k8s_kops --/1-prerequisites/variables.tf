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
variable "project" {}
variable "project_name" {}
variable "environment" {}
variable "encrypt" {}
variable "bucket" {}
variable "dynamodb_table" {}
variable "secondary_region" {}
