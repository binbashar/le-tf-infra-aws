module "terraform_backend" {
  source = "github.com/binbashar/terraform-aws-tfstate-backend.git?ref=v1.0.29"

  #
  # Bucket Name
  #
  delimiter = "-"
  namespace = var.project
  stage     = var.environment
  name      = "terraform-backend"

  #
  # Security
  #
  acl                           = "private"
  block_public_acls             = true
  block_public_policy           = true
  restrict_public_buckets       = true
  enable_server_side_encryption = var.encrypt
  enforce_ssl_requests          = true
  ignore_public_acls            = true

  #
  # Replication
  #
  bucket_replication_enabled = true

  notifications_sns             = false
  bucket_lifecycle_enabled      = false
  billing_mode                  = "PROVISIONED"
  enable_point_in_time_recovery = false
  create_kms_key                = false # USE SSE-S3

  tags = local.tags

  providers = {
    aws.primary   = aws.main_region
    aws.secondary = aws.secondary_region
  }
}
