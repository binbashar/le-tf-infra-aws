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
# Workaround used to inject this variable's default value into a policy without
# causing a TF interpolation error.
#
variable "aws_username" {
    default = "${aws:username}"
}
