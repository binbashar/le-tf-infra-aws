module "terraform_backend" {
  source = "github.com/binbashar/terraform-aws-tfstate-backend.git?ref=v1.0.7"

  #
  # Bucket Name and Region
  #
  region    = var.region
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
