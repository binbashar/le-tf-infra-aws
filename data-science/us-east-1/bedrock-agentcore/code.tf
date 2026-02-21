#=============================#
# Validate artifact exists    #
#=============================#
locals {
  artifact_full_path = "${path.module}/${var.artifact_path}"
}

#=============================#
# S3 Bucket for code artifact #
#=============================#
resource "aws_s3_bucket" "code" {
  bucket = "${local.name_prefix}-code"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "code" {
  bucket = aws_s3_bucket.code.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "code" {
  bucket = aws_s3_bucket.code.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "code" {
  bucket = aws_s3_bucket.code.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#=============================#
# Upload deployment package   #
#=============================#
resource "aws_s3_object" "agent" {
  bucket      = aws_s3_bucket.code.id
  key         = "agent.zip"
  source      = local.artifact_full_path
  source_hash = filemd5(local.artifact_full_path)
  tags        = local.tags

  lifecycle {
    precondition {
      condition     = fileexists(local.artifact_full_path)
      error_message = "Artifact not found at '${var.artifact_path}'. Build it first: cd examples/strands-agent && bash build.sh"
    }
  }
}
