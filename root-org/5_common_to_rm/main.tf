#
# AWS Billing Alerts
#
# Billing = U$S50
//module "aws_cost_mgmt_billing_alert_50" {
//  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/cost-mgmt-billing-alarm-bb?ref=v0.6"
//
//  aws_env                   = "${var.project}-${var.environment}-50"
//  monthly_billing_threshold = "${var.monthly_billing_threshold_50}"
//  currency                  = "${var.currency}"
//  aws_sns_topic_arn         = "${data.terraform_remote_state.sns.sns_topic_arn}"
//  tags                      = "${local.tags}"
//}