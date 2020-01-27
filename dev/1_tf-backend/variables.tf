#
# config/backend.config
#
#=============================#
# AWS Provider Settings       #
#=============================#
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "region_secondary" {
  type        = string
  description = "AWS Scondary Region for HA"
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
# Accounts                    #
#=============================#
variable "security_account_id" {
  type        = string
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  type        = string
  description = "Account: Shared Resources"
}

variable "dev_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

variable "cloudtrail_org_bucket" {
  type        = string
  description = "Cloudtrail centralized organization bucket"
}
