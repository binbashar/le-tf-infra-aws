module "terraform_backend" {
  source = "github.com/binbashar/terraform-aws-tfstate-backend.git?ref=v1.0.15"

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

  #
  # Replication
  #
  bucket_replication_enabled = true

  tags = local.tags

  providers = {
    aws.main_region      = aws.main_region
    aws.secondary_region = aws.secondary_region
  }
}
