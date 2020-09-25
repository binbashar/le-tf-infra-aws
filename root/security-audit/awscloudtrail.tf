module "cloudtrail" {
  source                        = "github.com/binbashar/terraform-aws-cloudtrail.git?ref=0.14.0"
  namespace                     = var.project
  stage                         = var.environment
  name                          = "cloudtrail-org"
  enable_logging                = "true"
  enable_log_file_validation    = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "true"
  s3_bucket_name                = data.terraform_remote_state.security_audit.outputs.bucket_id
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail.arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_events.arn
}

module "cloudtrail_api_alarms" {
  source = "github.com/binbashar/terraform-aws-cloudtrail-cloudwatch-alarms.git?ref=v0.5.2"

  region           = var.region
  log_group_name   = aws_cloudwatch_log_group.cloudtrail.name
  alarm_suffix     = "${var.environment}-account"
  metric_namespace = var.metric_namespace
  create_dashboard = var.create_dashboard
  # Uncomment if /notifications SNS is configured and you want to send notifications via slack
  sns_topic_arn = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring_sec # null (to deactivate)
}

#==================================================================#
# setup cloudwatch logs group in order to receive cloudtrail events
#==================================================================#
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "${var.project}-${var.environment}-cloudtrail"
  retention_in_days = "14"

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
      "arn:aws:logs:${var.region}:${var.root_account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:*",
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["logs:PutLogEvents"]

    resources = [
      "arn:aws:logs:${var.region}:${var.root_account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:*",
    ]
  }
}
