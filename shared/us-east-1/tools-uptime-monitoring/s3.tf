module "target_canary_s3_bucket" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v3.15.2"

  bucket = "${var.project}-${var.environment}-target-canary"

  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id      = "screenshots"
      enabled = true

      expiration = {
        days = 10
      }
    }
  ]

  tags = local.tags
}
