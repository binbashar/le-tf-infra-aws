# module "root-login-notifications" {
#   source = "github.com/binbashar/terraform-aws-root-login-notifications.git?ref=v2.1.1"

#   alarm_suffix   = "${var.environment}-account"
#   send_sns       = true
#   sns_topic_name = data.terraform_remote_state.notifications.outputs.sns_topic_name_monitoring_sec
# }
