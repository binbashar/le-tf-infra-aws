module "cloudtrail" {
  source                        = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/aws-cloudtrail-tf?ref=v0.2"
  namespace                     = "bb"
  stage                         = "account"
  name                          = "dev"
  enable_logging                = "true"
  enable_log_file_validation    = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "true"
  s3_bucket_name                = "bb-account-security"
}
