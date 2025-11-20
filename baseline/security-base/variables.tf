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
variable "inputs" {
  description = "Global inputs"
  type        = map(any)
  default     = {}
}
