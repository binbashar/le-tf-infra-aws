module "cloudtrail" {
  source                        = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/aws-cloudtrail-tf?ref=v0.2"
  namespace                     = "bb"
  stage                         = "account"
  name                          = "security"
  enable_logging                = "true"
  enable_log_file_validation    = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "true"
  s3_bucket_name                = "${module.cloudtrail_s3_bucket.bucket_id}"
}

module "cloudtrail_s3_bucket" {
  source    = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/aws-cloudtrail-s3-bucket-tf?ref=v0.2"
  namespace = "bb"
  stage     = "account"
  name      = "security"
  region    = "us-east-1"
  accountIDS = [
      "arn:aws:s3:::bb-account-security/*",
      "arn:aws:s3:::bb-account-security/AWSLogs/556823206064/*",
      "arn:aws:s3:::bb-account-security/AWSLogs/571945541201/*",
      "arn:aws:s3:::bb-account-security/AWSLogs/187030804674/*"
      ]
}

