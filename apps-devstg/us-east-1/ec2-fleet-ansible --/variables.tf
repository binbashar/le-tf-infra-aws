#
# /config/backend.tfvars
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
# /config/account.tfvars
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

variable "enable_tgw_multi_region" {
  description = "Enable Multi-Region Transit Gateway"
  type        = bool
  default     = false
}

variable "tgw_cidrs" {
  description = "CDIR blocks handled by the TGW"
  type        = list(string)
}

#
# Module Specific Variable
#
#=============================#
#  EC2 Attributes             #
#=============================#
variable "aws_ami_os_id" {
  type        = string
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "aws_ami_os_owner" {
  type        = string
  description = "AWS AMI Operating System Owner, eg: 099720109477 for Canonical "
  default     = "099720109477"
}
