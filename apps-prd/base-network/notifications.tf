module "vpc-natgw-notifications" {
  source = "github.com/binbashar/terraform-aws-natgw-notifications.git?ref=v0.0.5"

  alarm_suffix             = "${var.environment}-account"
  alarm_period             = 3600
  alarm_evaluation_periods = 1
  send_sns                 = true
  sns_topic_name           = data.terraform_remote_state.notifications.outputs.sns_topic_name_monitoring
}
