module "cloudtrail" {
  source                        = "github.com/binbashar/terraform-aws-cloudtrail.git?ref=0.14.0"
  namespace                     = var.project
  stage                         = var.environment
  name                          = "cloudtrail-org"
  enable_logging                = "true"
  enable_log_file_validation    = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "true"
  s3_bucket_name                = module.cloudtrail_s3_bucket.bucket_id
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail.arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_events.arn
  kms_key_arn                   = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}

module "cloudtrail_s3_bucket" {
  source                 = "github.com/binbashar/terraform-aws-cloudtrail-s3-bucket.git?ref=0.12.0"
  namespace              = var.project
  stage                  = var.environment
  name                   = "cloudtrail-org"
  lifecycle_rule_enabled = var.lifecycle_rule_enabled
  #
  # NOTE: Had to pass null here because there seems to be an issue with the
  #       module which is trying to set tags to lifecycle policies
  #
  lifecycle_tags  = null

  #
  # NOTE: this actually isn't supported by the module. The issue is reported
  # here: https://github.com/cloudposse/terraform-aws-cloudtrail-s3-bucket/issues/19
  #
  # policy          = data.aws_iam_policy_document.cloudtrail_s3_bucket.json
  acl             = "private"
  expiration_days = 120
}

module "cloudtrail_api_alarms" {
  source = "github.com/binbashar/terraform-aws-cloudtrail-cloudwatch-alarms.git?ref=v0.5.3"

  region           = var.region
  log_group_name   = aws_cloudwatch_log_group.cloudtrail.name
  alarm_suffix     = "${var.environment}-account"
  metric_namespace = var.metric_namespace
  create_dashboard = var.create_dashboard
  sns_topic_arn    = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring_sec # null (to deactivate)

  # Set custom threshold to the following alarms
  alarm_threshold = {
    "AuthorizationFailureCount" = "10"
  }
  # Set custom period to the following alarms
  alarm_period = {
    "AuthorizationFailureCount" = "600"
  }
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
      "arn:aws:logs:${var.region}:${var.security_account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:*",
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["logs:PutLogEvents"]

    resources = [
      "arn:aws:logs:${var.region}:${var.security_account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:*",
    ]
  }
}
