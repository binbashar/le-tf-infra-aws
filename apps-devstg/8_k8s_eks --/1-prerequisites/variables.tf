#
# config/backend.config
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "region" {
  description = "AWS Region"
}

variable "region_secondary" {
  description = "AWS Scondary Region for HA"
}

variable "profile" {
  description = "AWS Profile"
}

variable "bucket" {}
variable "dynamodb_table" {}
variable "encrypt" {}

#
# config/base.config
#
#=============================#
# Project Variables           #
#=============================#
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
# config/extra.config
#
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "security_account_id" {
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  description = "Account: Shared Resources"
}

variable "appsdevstg_account_id" {
  description = "Account: Dev Modules & Libs"
}

variable "cloudtrail_org_bucket" {}

#===========================================#
# Networking                                #
#===========================================#
variable "vpc_apps_devstg_eks_created" {
  description = "true if Dev account EKS VPC is created for Peering purposes"
  type        = bool
  default     = true
}

variable "vpc_apps_devstg_eks_dns_assoc" {
  description = "true if Dev account EKS VPC exists and needs DNS association"
  type        = bool
  default     = true
}
