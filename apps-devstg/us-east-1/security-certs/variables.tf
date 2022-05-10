#
# /apps-devstg/config/backend.tfvars
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "region" {
  type        = string
  description = "AWS Region"
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
# /apps-devstg/config/account.tfvars
#
#========================#
# Account Configuration  #
#========================#
variable "environment" {
  type        = string
  description = "Environment Name"
}

#
# /config/common.tfvars
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

#
# config/extra.config
#
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "region_primary" {
  type        = string
  description = "AWS Primary Region for HA"
}

variable "region_secondary" {
  type        = string
  description = "AWS Scondary Region for HA"
}

variable "accounts" {
  type        = map(any)
  description = "Accounts descriptions"
}

variable "root_account_id" {
  type        = string
  description = "Account: Root"
}

variable "security_account_id" {
  type        = string
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  type        = string
  description = "Account: Shared Resources"
}

variable "network_account_id" {
  type        = string
  description = "Account: Networking Resources"
}

variable "appsdevstg_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

variable "appsprd_account_id" {
  type        = string
  description = "Account: Prod Modules & Libs"
}

#=============================#
# Hashicorp Vault Vars        #
#=============================#
variable "vault_address" {
  type        = string
  description = "Hashicorp vault api endpoint address"
}

variable "vault_token" {
  type        = string
  description = "Hashicorp vault admin token"
}

#=============================#
# Networking                  #
#=============================#
variable "enable_tgw" {
  description = "Enable Transit Gateway Support"
  type        = bool
  default     = false
}

#=============================#
# ACM DNS variables           #
#=============================#
variable "profile_shared" {
  type        = string
  description = "Shared account aws iam profile in order to update Route53 DNS service"
  default     = "bb-shared-devops"
}
