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
  description = "AWS Scondary Region for HA"
}

#===========================================#
# DNS                                       #
#===========================================#
variable "vpc_shared_dns_assoc" {
  description = "true if Shared account VPC exists and needs DNS association"
  type        = bool
  default     = true
}
