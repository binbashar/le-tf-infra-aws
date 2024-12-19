#
# Vault Backend: S3 bucket
#
module "vault_backend" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v1.20.0"

  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = true

  replication_configuration = {
    role = aws_iam_role.replication.arn

    rules = [
      {
        id     = "ReplicationRule"
        status = "Enabled"

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        destination = {
          bucket             = "arn:aws:s3:::${local.destination_bucket_name}"
          storage_class      = "STANDARD"
          replica_kms_key_id = data.terraform_remote_state.keys-dr.outputs.aws_kms_key_arn
          account_id         = data.aws_caller_identity.current.account_id
          access_control_translation = {
            owner = "Destination"
          }
        }
      }
    ]
  }

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags

  depends_on = [module.vault_backend_replica]
}

#
# Vault Bucket Replica
#
module "vault_backend_replica" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v1.20.0"

  providers = {
    aws = aws.replica
  }

  bucket = local.destination_bucket_name
  acl    = "private"

  versioning = {
    enabled = true
  }

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}
