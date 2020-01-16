#===========================================#
# AWS Provider Settings                     #
#===========================================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#===========================================#
# Project Variables                         #
#===========================================#
variable "project" {
  description = "Project Name"
}

variable "project_long" {
  description = "Project Long Name"
}

variable "environment" {
  description = "Environment Name"
}

variable "bucket" {}
variable "encrypt" {}

#===========================================#
# Accounts                                  #
#===========================================#
variable "security_account_id" {
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  description = "Account: Shared Resources"
}

variable "dev_account_id" {
  description = "Account: Dev Modules & Libs"
}

#===========================================#
# Security                                  #
#===========================================#
variable "cloudtrail_org_bucket" {
  description = "Cloudtrail centralized organization bucket"
}

variable "compute_ssh_key_name" {
  description = "EC2 ssh public key name"
  default     = "bb-infra-deployer"
}

variable "compute_ssh_public_key" {
  description = "EC2 ssh public key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwqY8pH6XktrIOZ4JK2eaWg4QRkIkr2ua4IqfPhU+RPzCdBLCv1imX9kevX+dd0rplQAHibagouwLie99rEv1qR1Lt82jOXkBACdLCDaW5CGn2LTKFHN3Lm+oFRu9jzKRB6d2hm0qNuECvL1X2QAgbeGq5RDTwxVLg33l/EggpNbZZoh11w/UrSkvy2wYuYtLAN5oGj47+mvxpRvrcYK99zMOla6M6C5MrxllxaNcZXaO7cHZFLNFG5mbfJ/MdzHy9u46v3cf012UzhkrSkCqLSz2r2U25gKNWcOqmE0AMNW6qLBWmXnG+wUEBebX9v4KDRKfjbxpWJLQdr5CHav4l delivery@delivery-I7567"
}

variable "metric_namespace" {
  description = "A namespace for grouping all of the metrics together"
  default     = "CISBenchmark"
  type        = string
}

variable "create_dashboard" {
  description = "When true a dashboard that displays the statistics as a line graph will be created in CloudWatch"
  default     = true
  type        = bool
}

variable "kms_key_name" {
  description = "KMS key solution name, e.g. 'app' or 'jenkins'"
  default     = "kms"
  type        = string
}