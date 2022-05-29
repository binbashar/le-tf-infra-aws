#==============================================================#
# Terraform AWS Backend Settings (shared/config/backend.tfvars #
#==============================================================#
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

#==========================================#
# Project Variables (config/common.tfvars) #
#==========================================#
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

variable "region_secondary" {
  type        = string
  description = "AWS Secondary Region for HA"
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

variable "appsdevstg_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

#=================#
# Layer Variables #
#=================#
variable "prefix" {
  type        = string
  description = "A prefix string to name resources. Eg ofs (object file shares)"
  default     = "ofs"
}

variable "usernames" {
  type        = list(string)
  description = "Users List: new users can be onboarded by adding entries to this list."
  default = [
    "jane.doe",
    "john.doe",
    #EOL#
  ]
}
