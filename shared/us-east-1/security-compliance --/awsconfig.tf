#=============================#
# AWS Config Module           #
#=============================#

#
# AWS Config Logs AES256 SSE Bucket
#
module "config_logs" {
  source = "github.com/binbashar/terraform-aws-logs.git?ref=v10.3.0"

  s3_bucket_name          = "${var.project}-${var.environment}-awsconfig-logs"
  default_allow           = false # Whether all services included in this module should be allowed to write to the bucket by default.
  allow_config            = true  # Allow Config service to log to bucket.
  config_logs_prefix      = "${var.project}-${var.environment}-awsconfig"
  s3_log_bucket_retention = 90
}

#
# Module instantiation
#
module "terraform-aws-config" {
  source                         = "github.com/binbashar/terraform-aws-config.git?ref=v4.3.0"
  config_logs_bucket             = data.terraform_remote_state.security-security-compliance.outputs.aws_logs_bucket
  config_name                    = "${var.project}-${var.environment}-awsconfig"
  config_logs_prefix             = "${var.project}-${var.environment}-awsconfig"
  config_max_execution_frequency = "TwentyFour_Hours"
  config_delivery_frequency      = "Six_Hours"

  # Aggregate data from all organization accounts on this account
  aggregate_organization = false

  # IAM Config Rules w/ password policy check
  check_root_account_mfa_enabled   = true
  check_iam_group_has_users_check  = true
  check_iam_user_no_policies_check = true
  check_iam_password_policy        = true
  password_require_uppercase       = true
  password_require_lowercase       = true
  password_require_symbols         = true
  password_require_numbers         = true
  password_min_length              = 30
  password_reuse_prevention        = 5
  password_max_age                 = 60

  # ACM Config Rule
  check_acm_certificate_expiration_check = true
  acm_days_to_expiration                 = 14

  # Cloudtrail Config Rules
  check_multi_region_cloud_trail        = true
  check_cloudtrail_enabled              = true
  check_cloud_trail_encryption          = true
  check_cloud_trail_log_file_validation = true

  # GuardDuty Config Rule
  check_guard_duty = true

  # RDS Config Rules
  check_rds_public_access               = true
  check_rds_storage_encrypted           = true
  check_rds_snapshots_public_prohibited = true

  # EC2 & VPC Config Rules
  check_eip_attached           = true
  check_instances_in_vpc       = true
  check_ec2_volume_inuse_check = true
  check_ec2_encrypted_volumes  = true

  # S3 Config Rules
  check_s3_bucket_public_write_prohibited = true

  # Tags Config Rules
  check_required_tags          = true
  required_tags_resource_types = ["S3::Bucket", "EC2::Instances"]
  required_tags = {
    tag1Key   = "Terraform"
    tag1Value = "true"
    tag2Key   = "Environment"
    tag3Value = var.environment
  }
  check_approved_amis_by_tag = true
  ami_required_tag_key_value = "ApprovedAMI:true"
}
