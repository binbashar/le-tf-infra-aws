# -----------------------------------------------------------------------------
# Bucket Specs:
#  - Encrypted: Yes [HIPAA]
#  - Logging: Yes [HIPAA]
#  - Versioned: Yes [HIPAA]
#  - Enforce HTTPS: Yes [HIPAA]
#  - Private (ACL, Bucket Policy): Yes [HIPAA]
#  - Replicated: TBD -- For the sake of disaster recovery, still kind of easy to set up at a later time
#  - Storage Lifecycle: TBD -- For the sake of cost optimization; can be easily set up at any time but people tend to forget about it until costs reveal the mistake
#  - MFA Delete: TBD -- For the sake of data safety, but can be easily set up at any time
# -----------------------------------------------------------------------------
module "user_buckets" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v2.4.0"

  for_each = toset(var.usernames)

  bucket        = "${var.project}-${var.prefix}-user-${each.key}-files"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.user_logging_buckets[each.key].s3_bucket_id
    target_prefix = "logs/"
  }

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}

module "user_logging_buckets" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v2.4.0"

  for_each = toset(var.usernames)

  bucket                                = "${var.project}-${var.prefix}-user-${each.key}-files-logs"
  #TODO: Migrate module to newest version.
  #ACL commented because the ObjectOwnership now is BucketOwnerEnforced by default and disables the ACL.
  #acl                                  = "log-delivery-write"
  force_destroy                         = true
  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_deny_insecure_transport_policy = true
}
