module "terraform_backend" {
  source = "git::git@github.com:binbashar/terraform-aws-tfstate-backend.git?ref=v1.0.4"

  #
  # Bucket Name and Region
  #
  region    = var.region
  delimiter = "-"
  namespace = var.project
  stage     = var.environment
  name      = "terraform-state-storage-s3"

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
  bucket_replication_region  = var.region_secondary
  bucket_replication_profile = var.profile

  tags = local.tags
}
