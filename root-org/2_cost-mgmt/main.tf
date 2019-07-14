#
# AWS Billing Alerts
#
# Billing = U$S50
module "aws_cost_mgmt_billing_alert_50" {
  source = "git::git@github.com:binbashar/terraform-aws-cost-billing-alarm.git?ref=v0.0.2"

  aws_env                   = "${var.project}-${var.environment}-50"
  monthly_billing_threshold = "${var.monthly_billing_threshold_50}"
  currency                  = "${var.currency}"
  aws_sns_topic_arn         = "${data.terraform_remote_state.sns.sns_topic_arn}"
  tags                      = "${local.tags}"
}
# Billing = U$S100
module "aws_cost_mgmt_billing_alert_100" {
  source = "git::git@github.com:binbashar/terraform-aws-cost-billing-alarm.git?ref=v0.0.2"

  aws_env                   = "${var.project}-${var.environment}-100"
  monthly_billing_threshold = "${var.monthly_billing_threshold_100}"
  currency                  = "${var.currency}"
  aws_sns_topic_arn         = "${data.terraform_remote_state.sns.sns_topic_arn}"
  tags                      = "${local.tags}"
}

#
# AWS Budget
#
# Budget = U$S100 at 50%
module "aws_cost_mgmt_budget_notif_50" {
  source = "git::git@github.com:binbashar/terraform-aws-cost-budget.git?ref=v0.0.2"

  aws_env                 = "${var.environment}-50-percent"
  currency                = "${var.currency}"
  limit_amount            = "${var.monthly_billing_threshold_100}"
  time_unit               = "${var.time_unit}"
  time_period_start       = "${var.time_period_start}"
  notification_threshold  = "${var.notification_threshold_50}"
  aws_sns_topic_arn       = "${data.terraform_remote_state.sns.sns_topic_arn}"
}

# Budget = U$S100 at 100%
module "aws_cost_mgmt_budget_notif_100" {
  source = "git::git@github.com:binbashar/terraform-aws-cost-budget.git?ref=v0.0.2"

  aws_env                 = "${var.environment}-100-percent"
  currency                = "${var.currency}"
  limit_amount            = "${var.monthly_billing_threshold_100}"
  time_unit               = "${var.time_unit}"
  time_period_start       = "${var.time_period_start}"
  notification_threshold  = "${var.notification_threshold_100}"
  aws_sns_topic_arn       = "${data.terraform_remote_state.sns.sns_topic_arn}"
}
