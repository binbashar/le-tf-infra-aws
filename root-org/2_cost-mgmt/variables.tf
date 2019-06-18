#==============================#
# AWS Provider Settings        #
#==============================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#==============================#
# Project Variables            #
#==============================#
variable "project" {
  description = "Project Name"
}

variable "project_long" {
  description = "Project Long Name"
}

variable "environment" {
  description = "Environment Name"
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
  type        = "string"
  default     = "MONTHLY"
}

variable "time_period_start" {
  description = "Time to start."
  type        = "string"
  default     = "2019-01-01_00:00"
}

variable "notification_threshold_50" {
  description = "% Threshold when the notification should be sent."
  type        = "string"
  default     = 50
}

