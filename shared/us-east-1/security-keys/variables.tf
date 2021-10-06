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
variable "compute_ssh_key_name" {
  type        = string
  description = "EC2 ssh public key name"
  default     = "bb-infra-deployer"
}

variable "compute_ssh_public_key" {
  type        = string
  description = "EC2 ssh public key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwqY8pH6XktrIOZ4JK2eaWg4QRkIkr2ua4IqfPhU+RPzCdBLCv1imX9kevX+dd0rplQAHibagouwLie99rEv1qR1Lt82jOXkBACdLCDaW5CGn2LTKFHN3Lm+oFRu9jzKRB6d2hm0qNuECvL1X2QAgbeGq5RDTwxVLg33l/EggpNbZZoh11w/UrSkvy2wYuYtLAN5oGj47+mvxpRvrcYK99zMOla6M6C5MrxllxaNcZXaO7cHZFLNFG5mbfJ/MdzHy9u46v3cf012UzhkrSkCqLSz2r2U25gKNWcOqmE0AMNW6qLBWmXnG+wUEBebX9v4KDRKfjbxpWJLQdr5CHav4l delivery@delivery-I7567"
}

variable "kms_key_name" {
  type        = string
  description = "KMS key solution name, e.g. 'app' or 'jenkins'"
  default     = "kms"
}
