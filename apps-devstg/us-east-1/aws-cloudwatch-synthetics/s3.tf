module "target_canary_s3_bucket" {

  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v3.14.0"

  bucket = "${var.project}-${var.environment}-target-canary"

  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  tags = local.tags
}
