#=============================#
# AWS Provider Settings       #
#=============================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#=============================#
# Project Variables           #
#=============================#
variable "project" {
  description = "Project Name"
}

variable "project_long" {
  description = "Project Long Name"
}

variable "environment" {
  description = "Environment Name"
}

#=============================#
# Accounts                    #
#=============================#
variable "root_org_account_id" {
  description = "Account: Root Org"
}

variable "security_account_id" {
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  description = "Account: Shared Resources"
}

variable "dev_account_id" {
  description = "Account: Dev Modules & Libs"
}

#=============================#
# Notifications               #
#=============================#
variable "sns_topic_name" {
  description = ""
  default     = "sns-topic-slack-notify"
}

variable "slack_webhook_url" {
  description = ""
  default     = "https://hooks.slack.com/services/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"
}

variable "slack_channel" {
  description = ""
  default     = "bb-tools-monitoring"
}

variable "slack_username" {
  description = ""
  default     = "aws-binbash-org"
}
