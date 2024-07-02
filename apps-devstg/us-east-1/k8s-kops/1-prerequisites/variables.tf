#
# config/backend.config
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "project" {
  type        = string
  description = "Project Short Name"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "canada_region_primary" {
  type        = string
  description = "AWS Region for Canada"
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

variable "ssh_pub_key_path" {
  type        = string
  description = "The path to the public SSH key you want to use for the KOPS cluster"
}
#
# config/base.config
#
#=============================#
# Project Variables           #
#=============================#
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

#===========================================#
# IRSA                                      #
#===========================================#
variable "enable_irsa" {
  description = "Whether to activate IRSA in KOPS cluster (To use the IRSA bucket you should set 'block_public_policy = false' in security-base layer)"
  type        = bool
  default     = false
}

#===========================================#
# KARPENTER                                 #
#===========================================#
variable "enable_karpenter" {
  description = "Whether to activate Karpenter in KOPS cluster (IRSA has to be enabled)"
  type        = bool
  default     = false
}
