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
