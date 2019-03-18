module "cloudtrail" {
  source                        = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/aws-cloudtrail-tf?ref=v0.2"
  namespace                     = "${var.project}"
  stage                         = "account"
  name                          = "${var.environment}-cloudtrail"
  enable_logging                = "true"
  enable_log_file_validation    = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "true"
  s3_bucket_name                = "${module.cloudtrail_s3_bucket.bucket_id}"
}

module "cloudtrail_s3_bucket" {
  source    = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/aws-cloudtrail-s3-bucket-tf?ref=v0.2"
  namespace = "${var.project}"
  stage     = "account"
  name      = "${var.environment}"
  region    = "${var.region}"
  accountIDS = [
      "arn:aws:s3:::${var.project}-account-${var.environment}-cloudtrail/*",
      "arn:aws:s3:::${var.project}-account-${var.environment}-cloudtrail/AWSLogs/${var.security_account_id}/*",
      "arn:aws:s3:::${var.project}-account-${var.environment}-cloudtrail/AWSLogs/${var.shared_account_id}/*",
      "arn:aws:s3:::${var.project}-account-${var.environment}-cloudtrail/AWSLogs/${var.dev_account_id}/*"
      ]
}