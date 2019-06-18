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

variable "project_long" {
  description = "Project Long Name"
}

variable "environment" {
  description = "Environment Name"
}

#
# Accounts
#
variable "root_org_account_id" {
  description = "Account: Root Organization"
}

variable "security_account_id" {
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  description = "Account: Shared Resources"
}

variable "dev_account_id" {
  description = "Account: Dev Modules & Libs"
}

#
# Security
#
variable "cloudtrail_org_bucket" {
  description = "Cloudtrail centralized organization bucket"
}
