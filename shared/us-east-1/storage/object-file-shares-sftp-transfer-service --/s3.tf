#=======================================#
# Access Logs Bucket                    #
#=======================================#
module "log_bucket" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.1.1"

  bucket        = "${var.project}-${var.prefix}-sftp-customer-files-log"
  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "expiration"
      enabled = true
      expiration = {
        days = "30"
      }
    }
  ]

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  tags = local.tags
}

#=======================================#
# Main Bucket                           #
#=======================================#
module "s3_bucket" {
  ##############################################################
  # TO DO: Consider adding a lifecycle policy to this bucket   #
  ##############################################################
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.1.1"

  bucket        = "${var.project}-${var.prefix}-sftp-customer-files"
  force_destroy = true

  attach_deny_insecure_transport_policy = true

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "log/"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default = {
        #kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        sse_algorithm = "AES256"
      }
    }
  }

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  lifecycle_rule = [
    {
      id      = "expiration"
      enabled = true
      expiration = {
        days = "30"
      }
    }
  ]

  tags = local.tags
}