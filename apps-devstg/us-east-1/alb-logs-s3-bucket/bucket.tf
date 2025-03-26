#
# Create an S3 bucket for storing ALB access logs
#
module "s3_bucket_alb_logs" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.6.0"

  bucket = "${local.bucket_name}-logs"
  acl    = "log-delivery-write"
  # Allow deletion of non-empty bucket
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  lifecycle_rule = [
    {
      id      = "billing-objects-logs"
      enabled = true

      filter = {
        prefix = "/"
      }

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = local.transition

      expiration = {
        days = local.expiration_days  
      }

      noncurrent_version_expiration = {
        days = local.noncurrent_version_expiration_days
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