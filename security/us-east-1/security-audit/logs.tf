module "s3_bucket_alb_logs" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v3.7.0"
  count = var.eks_alb_logging ? 1 : 0

  bucket = "${var.project}-${var.environment}-alb-logs"
  acl    = "log-delivery-write"

  versioning = {
    enabled = true
  }

  # Allow deletion of non-empty bucket
  force_destroy = true

  attach_elb_log_delivery_policy = true  # Required for ALB logs
  attach_lb_log_delivery_policy  = true  # Required for ALB/NLB logs

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
