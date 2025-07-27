#================================#
# Common variables               #
#================================#

#
# config/backend.config
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "region_primary" {
  type        = string
  description = "AWS Region"
}

variable "regions_allowed" {
  type        = list
  description = "List of allowed AWS regions"
}

variable "profile" {
  type        = string
  description = "AWS Profile (required by the backend but also used for other resources)"
}

variable "bucket" {
  type        = string
  description = "AWS S3 TF State Backend Bucket"
}

variable "dynamodb_table" {
  type        = string
  description = "AWS DynamoDB TF Lock state table name"
}

variable "encrypt" {
  type        = bool
  description = "Enable AWS DynamoDB with server side encryption"
}

#
# config/base.config
#
#=============================#
# Project Variables           #
#=============================#
variable "project" {
  type        = string
  description = "Project Name"
}

variable "project_long" {
  type        = string
  description = "Project Long Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

#
# config/extra.config
#
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "region_secondary" {
  type        = string
  description = "AWS Secondary Region for HA"
}

variable "accounts" {
  type        = map(any)
  description = "Accounts Information"
}

variable "external_accounts" {
  type        = map(any)
  description = "External Accounts Information"
  default     = {}
}

#=============================#
# AWS SSO  Variables          #
#=============================#
variable "sso_role" {
  description = "SSO Role Name"
}

variable "sso_enabled" {
  type        = string
  description = "Enable SSO Service"
}

variable "sso_region" {
  type        = string
  description = "SSO Region"
}

variable "sso_start_url" {
  type        = string
  description = "SSO Start Url"
}

#===========================================#
# Networking                                #
#===========================================#
variable "enable_tgw" {
  description = "Enable Transit Gateway Support"
  type        = bool
  default     = false
}

variable "enable_tgw_multi_region" {
  description = "Enable Transit Gateway multi region support"
  type        = bool
  default     = false
}

variable "tgw_cidrs" {
  description = "CIDRs to be added as routes to public RT"
  type        = list(string)
  default     = []
}

#===========================================#
# Security compliance
#===========================================#
variable "enable_inspector" {
  description = "Turn inspector on/off"
  type        = bool
  default     = false
}

locals {
  regions = [var.region_primary, var.region_secondary, "global"]

  #Tries to find the current region for the current layer
  current_region = [for region in local.regions : region if can(regex(region, "${path.cwd}"))][0]

  #Split the full path of the layer using the region, in order to get the layer path (after the region)
  layer_name = trimprefix(split(local.current_region, "${path.cwd}")[1], "/")
}

