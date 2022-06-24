#=============================#
# Notifications               #
#=============================#
#
# AWS SNS -> Lambda -> Slack: tools-monitoring
#
variable "sns_topic_name_monitoring" {
  description = ""
  default     = "sns-topic-slack-notify-monitoring"
}

#
# AWS SNS -> Lambda -> Slack: tools-monitoring-sec
#
variable "sns_topic_name_monitoring_sec" {
  description = ""
  default     = "sns-topic-slack-notify-monitoring-sec"
}

variable "sns_topic_name_costs" {
  description = ""
  default     = "sns-topic-costs"
}

variable "costs_email_addresses" {
  description = "List of mails addresses to send costs alerts"
  type        = list(string)
  default     = ["info@binbash.com.ar"]
}
