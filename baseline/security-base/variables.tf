#=============================#
# Notifications               #
#=============================#
#
# AWS SNS -> Lambda -> Slack: tools-monitoring-sec
#
variable "sns_topic_name_monitoring_sec" {
  description = ""
  default     = "sns-topic-slack-notify-monitoring-sec"
}

#=============================#
# Settings Variables          #
#=============================#
variable "parameters" {
  description = "Global parameters"
  type        = map(any)
  default     = {}
}

variable "settings" {
  description = "Settings configuration"
  type        = any
  default     = {}
}

variable "accounts" {
  description = "Accounts configuration"
  type        = any
  default     = {}
}

variable "accounts_settings" {
  description = "Account settings by region"
  type        = any
  default     = {}
}

variable "account_name" {
  description = "Account name"
  type        = string
}
