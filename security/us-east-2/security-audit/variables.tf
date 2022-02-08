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

variable "vault_address" {
  type        = string
  description = "Vault Address"
}

variable "vault_token" {
  type        = string
  description = "Vault Token"
}

#===========================================#
# Security                                  #
#===========================================#
variable "lifecycle_rule_enabled" {
  type        = bool
  description = "Enable lifecycle events on this bucket"
  default     = true
}

variable "metric_namespace" {
  type        = string
  description = "A namespace for grouping all of the metrics together"
  default     = "CISBenchmark"
}

variable "create_dashboard" {
  type        = bool
  description = "When true a dashboard that displays the statistics as a line graph will be created in CloudWatch"
  default     = true
}

variable "metrics" {
  type        = any
  description = "Metrics definitions"
  default     = {}
}

variable "alarm_suffix" {
  type        = string
  description = "Alarm name suffix. You can use it to separate different AWS account. Set to `null` to avoid adding a suffix."
  default     = null
}

variable "enable_tgw" {
  description = "Enable Transit Gateway Support"
  type        = bool
  default     = false
}

variable "enable_tgw_multi_region" {
  description = "Enable Transit Gateway Support"
  type        = bool
  default     = false
}

variable "tgw_cidrs" {
  description = "CIDRs to be added as routes to public RT"
  type        = list(string)
  default     = []
}

#===========================================#
# Replication                               #
#===========================================#
variable "enable_cloudtrail_bucket_replication" {
  type        = bool
  description = "Enable CloudTrail bucket replication"
  default     = true
}

variable "enable_config_bucket_replication" {
  type        = bool
  description = "Enable Config bucket replication"
  default     = true
}
