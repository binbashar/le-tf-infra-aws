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
  default = "dev"
}

#===========================================#
# Accounts                                  #
#===========================================#
variable "shared_account_id" {
  description = "Account: Shared Resources"
}

variable "security_account_id" {
  description = "Security & Users Management Account ID"
}

variable "dev_account_id" {
  description = "Dev/Stage Account ID"
}

variable "shared_aws_internal_zone_id" {
  description = "Internal DNS zone for Applications Dev/Stage kubernetes"
}
