module "cloudtrail" {
  source                        = "git::git@github.com:binbashar/terraform-aws-cloudtrail.git?ref=v0.7.2"
  namespace                     = "${var.project}"
  stage                         = "${var.environment}"
  name                          = "cloudtrail-org"
  enable_logging                = "true"
  enable_log_file_validation    = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "true"
  s3_bucket_name                = "${module.cloudtrail_s3_bucket.bucket_id}"
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}"
  cloud_watch_logs_role_arn     = "${aws_iam_role.cloudtrail_cloudwatch_events.arn}"
}

module "cloudtrail_s3_bucket" {
  source                  = "git::git@github.com:binbashar/terraform-aws-cloudtrail-s3-bucket.git?ref=v0.3.5"
  namespace               = "${var.project}"
  stage                   = "${var.environment}"
  name                    = "cloudtrail-org"
  region                  = "${var.region}"
  lifecycle_rule_enabled  = "${var.lifecycle_rule_enabled}"
  lifecycle_tags          = "${local.tags}"

  accountIDS = [
    "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*",
    "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/AWSLogs/${var.security_account_id}/*",
    "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/AWSLogs/${var.shared_account_id}/*",
    "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/AWSLogs/${var.dev_account_id}/*",
  ]
}

#==================================================================#
# setup cloudwatch logs group in order to receive cloudtrail events
#==================================================================#
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "${var.project}-${var.environment}-cloudtrail"
  retention_in_days = "14"

  tags = {
    project     = "${var.project}"
    environment = "${var.environment}"
  }
}

#==================================================================#
# setup role and policy to allow cloudtrail to write to cloudwatch
#==================================================================#
resource "aws_iam_role" "cloudtrail_cloudwatch_events" {
  name               = "CloudtrailCloudwatchEvents"
  assume_role_policy = "${data.aws_iam_policy_document.assume_policy.json}"
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals = {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_events_policy" {
  name   = "CloudtrailCloudwatchEvents"
  role   = "${aws_iam_role.cloudtrail_cloudwatch_events.id}"
  policy = "${data.aws_iam_policy_document.cloudtrail_role_policy.json}"
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
