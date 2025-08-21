resource "aws_s3_bucket" "kyb_input" {
  bucket = local.input_bucket_name
  tags   = merge(local.tags, { Name = local.input_bucket_name })
}

resource "aws_s3_bucket" "kyb_output" {
  bucket = local.output_bucket_name
  tags   = merge(local.tags, { Name = local.output_bucket_name })
}

resource "aws_s3_bucket_versioning" "kyb_input" {
  count  = var.enable_s3_versioning ? 1 : 0
  bucket = aws_s3_bucket.kyb_input.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "kyb_output" {
  count  = var.enable_s3_versioning ? 1 : 0
  bucket = aws_s3_bucket.kyb_output.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kyb_input" {
  bucket = aws_s3_bucket.kyb_input.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_encryption ? data.terraform_remote_state.keys.outputs.aws_kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kyb_output" {
  bucket = aws_s3_bucket.kyb_output.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_encryption ? data.terraform_remote_state.keys.outputs.aws_kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "kyb_input" {
  bucket = aws_s3_bucket.kyb_input.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "kyb_output" {
  bucket = aws_s3_bucket.kyb_output.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "kyb_input" {
  bucket = aws_s3_bucket.kyb_input.id

  rule {
    id     = "transition-old-objects"
    status = "Enabled"

    transition {
      days          = var.s3_lifecycle_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.s3_glacier_days
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "kyb_output" {
  bucket = aws_s3_bucket.kyb_output.id

  rule {
    id     = "transition-old-objects"
    status = "Enabled"

    transition {
      days          = var.s3_lifecycle_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.s3_glacier_days
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "kyb_input" {
  bucket = aws_s3_bucket.kyb_input.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.kyb_input.arn,
          "${aws_s3_bucket.kyb_input.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "kyb_output" {
  bucket = aws_s3_bucket.kyb_output.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.kyb_output.arn,
          "${aws_s3_bucket.kyb_output.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "kyb_input" {
  bucket = aws_s3_bucket.kyb_input.id

  eventbridge = true
}