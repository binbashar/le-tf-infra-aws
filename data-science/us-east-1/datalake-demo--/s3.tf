module "s3_bucket_data_raw" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.2.1"

  bucket        = "${local.name}-data-raw-bucket"
  acl           = null
  force_destroy = true

  attach_policy = false
  #policy        = data.aws_iam_policy_document.bucket_policy.json

  # replication_configuration = {
  #   role = aws_iam_role.replication.arn

  #   rules = [
  #     {
  #       id     = "ReplicationRule"
  #       status = "Enabled"

  #       delete_marker_replication = false

  #       source_selection_criteria = {
  #         sse_kms_encrypted_objects = {
  #           enabled = true
  #         }
  #       }

  #       destination = {
  #         bucket             = "arn:aws:s3:::${local.bucket_name_replica}"
  #         storage_class      = "STANDARD"
  #         replica_kms_key_id = data.terraform_remote_state.keys-dr.outputs.aws_kms_key_arn
  #         account_id         = data.aws_caller_identity.current.account_id
  #         access_control_translation = {
  #           owner = "Destination"
  #         }
  #       }
  #     }
  #   ]
  # }

  versioning = {
    enabled = true
  }

  # logging = {
  #   target_bucket = module.log_bucket_demo_files.s3_bucket_id
  #   target_prefix = "logs/"
  # }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  /* #
   # Error: Error putting S3 replication configuration: InvalidRequest:
   # Replication configuration cannot be applied to an Object Lock enabled bucket
   #
  object_lock_configuration = {
    object_lock_enabled = "Enabled"
    rule = {
      default_retention = {
        mode  = "GOVERNANCE"
        years = 1
      }
    }
  }*/

  lifecycle_rule = [
    {
      id      = "billing-objects"
      enabled = true
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 1825
        # 5 years
      }

      noncurrent_version_expiration = {
        days = 1095
        # 2 years
      }
    },
  ]

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}


module "s3_bucket_data_processed" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.2.1"

  bucket        = "${local.name}-data-processed-bucket"
  acl           = null
  force_destroy = true

  attach_policy = false
  #policy        = data.aws_iam_policy_document.bucket_policy.json

  # replication_configuration = {
  #   role = aws_iam_role.replication.arn

  #   rules = [
  #     {
  #       id     = "ReplicationRule"
  #       status = "Enabled"

  #       delete_marker_replication = false

  #       source_selection_criteria = {
  #         sse_kms_encrypted_objects = {
  #           enabled = true
  #         }
  #       }

  #       destination = {
  #         bucket             = "arn:aws:s3:::${local.bucket_name_replica}"
  #         storage_class      = "STANDARD"
  #         replica_kms_key_id = data.terraform_remote_state.keys-dr.outputs.aws_kms_key_arn
  #         account_id         = data.aws_caller_identity.current.account_id
  #         access_control_translation = {
  #           owner = "Destination"
  #         }
  #       }
  #     }
  #   ]
  # }

  versioning = {
    enabled = true
  }

  # logging = {
  #   target_bucket = module.log_bucket_demo_files.s3_bucket_id
  #   target_prefix = "logs/"
  # }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  /* #
   # Error: Error putting S3 replication configuration: InvalidRequest:
   # Replication configuration cannot be applied to an Object Lock enabled bucket
   #
  object_lock_configuration = {
    object_lock_enabled = "Enabled"
    rule = {
      default_retention = {
        mode  = "GOVERNANCE"
        years = 1
      }
    }
  }*/

  lifecycle_rule = [
    {
      id      = "billing-objects"
      enabled = true
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 1825
        # 5 years
      }

      noncurrent_version_expiration = {
        days = 1095
        # 2 years
      }
    },
  ]

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}