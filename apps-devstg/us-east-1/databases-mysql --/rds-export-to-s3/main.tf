locals {
  bucket_name = "${var.project}-${var.environment}-rds-exported-snapshots"
  tags = {
    Name        = "rds-export-to-s3"
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}

# -----------------------------------------------------------------------------
# RDS Export To S3
# -----------------------------------------------------------------------------
module "rds_export_to_s3" {
  source = "github.com/binbashar/terraform-aws-rds-export-to-s3.git?ref=v0.4.3"

  # Set a prefix for naming resources
  prefix = "mysql"

  create_customer_kms_key = true

  # The database name whose RDS snapshots will be exported to S3
  database_names = data.terraform_remote_state.databases-mysql.outputs.bb_reference_db_id

  # The RDS snapshots events that should be included: RDS Automated cluster snapshot (RDS-EVENT-0091) and/or Manual cluster snapshot (RDS-EVENT-0042)
  rds_event_ids = "RDS-EVENT-0091"

  # The S3 bucket that will store the exported snapshots
  snapshots_bucket_name = module.bucket.s3_bucket_id

  # The SNS topic that will receive notifications about exported snapshots events
  notifications_topic_arn = "arn:aws:sns:us-east-1:${var.accounts.apps-devstg.id}:sns-topic-slack-notify-monitoring-sec"

  # A logging level which is useful for debugging
  log_level = "DEBUG"

  tags = local.tags
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

  # lifecycle_rule = [
  #   {
  #     id      = "all"
  #     enabled = true
  #     prefix  = "/"

  #     tags = {
  #       rule      = "all"
  #     }

  #     transition = [
  #       {
  #         days          = 30
  #         storage_class = "ONEZONE_IA"
  #       },
  #       {
  #         days          = 60
  #         storage_class = "GLACIER"
  #       }
  #     ]

  #     expiration = {
  #       days = 90
  #     }

  #     noncurrent_version_expiration = {
  #       days = 30
  #     }
  #   }
  # ]

  # replication_configuration = {
  #   role = aws_iam_role.replication.arn

  #   rules = [
  #     {
  #       id       = "main"
  #       status   = "Enabled"
  #       priority = 10

  #       source_selection_criteria = {
  #         sse_kms_encrypted_objects = {
  #           enabled = true
  #         }
  #       }

  #       filter = {
  #         prefix = "/"
  #       }

  #       destination = {
  #         bucket             = "arn:aws:s3:::${local.bucket_name}"
  #         storage_class      = "STANDARD"
  #         replica_kms_key_id = aws_kms_key.replica.arn
  #         account_id         = data.aws_caller_identity.current.account_id
  #         access_control_translation = {
  #           owner = "Destination"
  #         }
  #       }
  #     }
  #   ]
  # }

  #
  # object_lock_mode              = "GOVERNANCE"
  # object_lock_retain_until_date = formatdate("YYYY-MM-DD'T'hh:00:00Z", timeadd(timestamp(), "24h"))
  # object_lock_legal_hold_status = true
  #

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
