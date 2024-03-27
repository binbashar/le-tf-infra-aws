

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

variable "add_budget_service_permission" {
  type        = bool
  description = "Add permission to allow AWS budget to publish into this topic"
  default     = false
}
