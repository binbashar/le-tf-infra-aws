#
# Create an S3 bucket for storing ALB access logs
#
module "s3_bucket_alb_logs" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v3.15.2"

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
      prefix  = "logs/"

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
          }, {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }

      noncurrent_version_expiration = {
        days = 180
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