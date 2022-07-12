module "cloudtrail" {
  source                        = "github.com/binbashar/terraform-aws-cloudtrail.git?ref=0.20.1"
  namespace                     = var.project
  stage                         = var.environment
  name                          = "cloudtrail-org"
  enable_logging                = true
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true
  s3_bucket_name                = module.cloudtrail_s3_bucket.bucket_id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_events.arn
  kms_key_arn                   = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
  #is_organization_trail        = true
}

module "cloudtrail_s3_bucket" {
  source                 = "github.com/binbashar/terraform-aws-cloudtrail-s3-bucket.git?ref=0.23.1"
  namespace              = var.project
  stage                  = var.environment
  name                   = "cloudtrail-org"
  lifecycle_rule_enabled = var.lifecycle_rule_enabled
  versioning_enabled     = true
  #
  # NOTE: Had to pass null here because there seems to be an issue with the
  #       module which is trying to set tags to lifecycle policies
  #
  lifecycle_tags = null

  #
  # NOTE: this actually isn't supported by the module. The issue is reported
  # here: https://github.com/cloudposse/terraform-aws-cloudtrail-s3-bucket/issues/19
  #
  # policy          = data.aws_iam_policy_document.cloudtrail_s3_bucket.json
  acl             = "private"
  expiration_days = 120
}

module "cloudtrail_api_alarms" {
  source            = "github.com/binbashar/terraform-aws-cloudtrail-cloudwatch-alarms.git?ref=0.14.3"
  log_group_region  = var.region
  log_group_name    = aws_cloudwatch_log_group.cloudtrail.name
  metric_namespace  = var.metric_namespace
  dashboard_enabled = var.create_dashboard

  # Uncomment if /notifications SNS is configured and you want to send notifications via slack
  sns_topic_arn = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring_sec
  metrics       = local.metrics

  # KMS key use for encrypting the Amazon SNS topic.
  kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_id

}

#==================================================================#
# setup cloudwatch logs group in order to receive cloudtrail events
#==================================================================#
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "${var.project}-${var.environment}-cloudtrail"
  retention_in_days = "14"
  kms_key_id        = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  tags = local.tags
}

#==================================================================#
# setup role and policy to allow cloudtrail to write to cloudwatch
#==================================================================#
resource "aws_iam_role" "cloudtrail_cloudwatch_events" {
  name               = "CloudtrailCloudwatchEvents"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_events_policy" {
  name   = "CloudtrailCloudwatchEvents"
  role   = aws_iam_role.cloudtrail_cloudwatch_events.id
  policy = data.aws_iam_policy_document.cloudtrail_role_policy.json
}

data "aws_iam_policy_document" "cloudtrail_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogStream"]

    resources = [
      "arn:aws:logs:${var.region}:${var.accounts.security.id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:*",
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["logs:PutLogEvents"]

    resources = [
      "arn:aws:logs:${var.region}:${var.accounts.security.id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:*",
    ]
  }
}
