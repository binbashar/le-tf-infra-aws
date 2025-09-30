#================================
# S3 Bucket for Documents
#================================

resource "aws_s3_bucket" "documents" {
  bucket        = local.documents_bucket_name
  force_destroy = true
  tags          = merge(local.tags, { Purpose = "bedrock-agent-documents" })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [aws_s3_bucket_versioning.documents]
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

