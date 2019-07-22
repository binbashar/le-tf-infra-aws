#=============================#
# AWS Provider Settings       #
#=============================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#=============================#
# Project Variables           #
#=============================#
variable "environment" {
  description = "Environment Name"
}

#=============================#
# Accounts Data               #
#=============================#
variable "shared_account_id" {
  description = "Account: Shared Resources"
}

variable "dev_account_id" {
  description = "Account: Dev Modules & Libs"
}
