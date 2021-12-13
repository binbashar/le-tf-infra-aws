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

variable "vault_address" {
  type        = string
  description = "Vault Address"
}

variable "vault_token" {
  type        = string
  description = "Vault Token"
}

#=================#
# Layer Variables #
#=================#
variable "prefix" {
  type    = string
  default = "cfs"
}

variable "customers" {
  type = map(object({
    username       = string
    ssh_public_key = string
  }))
  default = {}
}

variable "server_endpoint_type" {
  type    = string
  default = "VPC"
}

variable "server_protocols" {
  type    = list(string)
  default = ["SFTP"]
}

variable "server_host_key" {
  type    = string
  default = null
}

variable "base_domain" {
  type    = string
  default = "binbash.com.ar"
}
