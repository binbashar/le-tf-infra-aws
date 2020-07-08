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
  type        = string
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

variable "appsprd_account_id" {
  type        = string
  description = "Account: Prod Modules & Libs"
}

variable "root_account_id" {
  description = "Account: Root Organization"
}

#==============================#
# Cost Mgmt                    #
#==============================#
#
# Billing cloudwatch alarm
#
variable "monthly_billing_threshold_50" {
  description = "Monthly billing threshold in dollars"
  default     = 50
}

variable "monthly_billing_threshold_100" {
  description = "Monthly billing threshold in dollars"
  default     = 100
}

variable "currency" {
  description = "Billing currency eg: dollars"
  default     = "USD"
}

#
# Budget
#
variable "time_unit" {
  description = "The length of time until a budget resets the actual and forecasted spend. Valid values: MONTHLY, QUARTERLY, ANNUALLY."
  type        = string
  default     = "MONTHLY"
}

variable "time_period_start" {
  description = "Time to start."
  type        = string
  default     = "2019-01-01_00:00"
}

variable "notification_threshold_50" {
  description = "% Threshold when the notification should be sent."
  type        = string
  default     = 50
}

variable "notification_threshold_75" {
  description = "% Threshold when the notification should be sent."
  type        = string
  default     = 75
}

variable "notification_threshold_100" {
  description = "% Threshold when the notification should be sent."
  type        = string
  default     = 100
}
