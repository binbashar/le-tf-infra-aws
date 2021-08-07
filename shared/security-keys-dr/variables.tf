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

#========================================#
# Project Variables (config/base.config) #
#========================================#
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

#=============================================#
# Accounts & Extra Vars (config/extra.config) #
#=============================================#
variable "region_secondary" {
  type        = string
  description = "AWS Scondary Region for HA"
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

#===========================================#
# Security                                  #
#===========================================#
variable "kms_key_name" {
  type        = string
  description = "KMS key solution name, e.g. 'app' or 'jenkins'"
  default     = "kms_dr"
}
