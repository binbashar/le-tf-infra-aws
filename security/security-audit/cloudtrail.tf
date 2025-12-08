#
# Create a centralized, multi-region, organizational trail in the Security account.
# IMPORTANT: before you can enable this, you must delegate the administration to
# the Security account from the Management account.
#
module "cloudtrail" {
  source = "github.com/binbashar/terraform-aws-cloudtrail.git?ref=0.24.0"
  name   = "${var.project}-${var.environment}-${var.cloudtrail_settings.name}"

  # Include global services such as Route 53 or IAM
  include_global_service_events = var.cloudtrail_settings.include_global_service_events
  is_multi_region_trail         = var.cloudtrail_settings.is_multi_region_trail
  is_organization_trail         = var.cloudtrail_settings.is_organization_trail

  # Enable to S3 and CloudWatch Logs (and store log validation files)
  enable_logging             = var.cloudtrail_settings.enable_logging
  enable_log_file_validation = var.cloudtrail_settings.enable_log_file_validation

  # Send event logs to S3
  s3_bucket_name = module.cloudtrail_s3_bucket.bucket_id
  #kms_key_arn    = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  # Enable for API alarms
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_events.arn
}

#
# Create an S3 bucket for storing CloudTrail event logs.
# This is typically used for setting a longer retention period than the 90
# days that CloudTrail provides by default.
#
module "cloudtrail_s3_bucket" {
  source                 = "github.com/binbashar/terraform-aws-cloudtrail-s3-bucket.git?ref=v0.28.0"
  name                   = "${var.project}-${var.environment}-cloudtrail-org"
  lifecycle_rule_enabled = var.cloudtrail_settings.s3_bucket.lifecycle_rule_enabled
  versioning_enabled     = var.cloudtrail_settings.s3_bucket.versioning_enabled
  acl                    = var.cloudtrail_settings.s3_bucket.acl
  expiration_days        = var.cloudtrail_settings.s3_bucket.expiration_days
  tags                   = var.cloudtrail_settings.tags
}

#
# Set up CloudWatch Alarms based on specific CloudTrail events.
# Refer to the file "metrics.auto.tfvars" to view the list of alarms and their specs.
#
module "cloudtrail_api_alarms" {
  source = "github.com/binbashar/terraform-aws-cloudtrail-cloudwatch-alarms.git?ref=0.14.3"

  # The log group whose logs will be used for configuring metric filters and alarms
  log_group_region = var.region
  log_group_name   = aws_cloudwatch_log_group.cloudtrail.name

  # The custom metrics that will be created via metric filters
  metrics = local.metrics

  # The namespace under which the custom metrics will live
  metric_namespace = var.monitoring_settings.metric.namespace

  # Whether to enable a custom dashboard using the custom metrics that will be created
  dashboard_enabled = var.monitoring_settings.metric.create_dashboard

  # Pass a custom SNS topic that will be hooked to the alarms that the module will create,
  # otherwise the module will use its own topic
  #sns_topic_arn = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring_sec

  # A KMS key that will be used for encrypting messages writtent to the SNS topic
  #kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_id
}

#
# Set up a CloudWatch log group to receive CloudTrail events
#
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "${var.project}-${var.environment}-${var.monitoring_settings.logs.group_name}"
  retention_in_days = var.monitoring_settings.logs.retention_in_days
  #kms_key_id        = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  tags = var.cloudtrail_settings.tags
}

#
# Create a role & policy for CloudTrail to write its logs to CloudWatch logs
#
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
