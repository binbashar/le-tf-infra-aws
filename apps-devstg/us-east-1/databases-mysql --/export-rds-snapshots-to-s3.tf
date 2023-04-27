locals {
  bucket_name = "${var.project}-${replace(var.environment, "apps-", "")}-binbash-mysql"
}

# -----------------------------------------------------------------------------
# RDS Export To S3 functions
# -----------------------------------------------------------------------------
module "rds_export_to_s3" {
  source = "git@github.com:binbashar/terraform-aws-rds-export-to-s3.git?ref=v0.4.0"

  # Set a prefix for naming resources
  #prefix = "binbashar"

  # Which RDS snapshots should be exported?
  database_names = "${var.project}-${replace(var.environment, "apps-", "")}-binbash-mysql"

  # Which bucket will store the exported snapshots?
  snapshots_bucket_name = module.bucket.s3_bucket_id
  #snapshots_bucket_name = "export-bucket-name"

  # To group objects in a bucket, S3 uses a prefix before object names. The forward slash (/) in the prefix represents a folder.
  snapshots_bucket_prefix = "rds_snapshots/"

  # Which RDS snapshots events should be included (RDS Aurora or/and RDS non-Aurora)?
  #rds_event_ids = "RDS-EVENT-0091, RDS-EVENT-0169"

  # Create customer managed key or use default AWS S3 managed key. If set to 'false', then 'customer_kms_key_arn' is used.
  create_customer_kms_key = false

  # Provide CMK if 'create_customer_kms_key = false'
  #customer_kms_key_arn = "arn:aws:kms:us-east-1:523857393444:key/b7a1d584-29cf-4f21-a69f-57ca8eaa1c77"

  # SNS topic for export monitor notifications
  create_notifications_topic = true

  # Which topic should receive notifications about exported snapshots events? Only required if 'create_notifications_topic = false'
  #notifications_topic_arn = "arn:aws:sns:us-east-1:000000000000:sns-topic-slack-notifications"

  # Set the logging level
  # log_level = "DEBUG"

  tags = local.tags
  #tags = { Deployment = "binbachar-export" }
}


# -----------------------------------------------------------------------------
# This bucket will be used for storing the exported RDS snapshots.
# -----------------------------------------------------------------------------
module "bucket" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v2.6.0"

  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}
