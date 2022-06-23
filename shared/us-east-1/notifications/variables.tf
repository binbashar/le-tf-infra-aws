#================================#
# Local variables                #
#================================#
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
