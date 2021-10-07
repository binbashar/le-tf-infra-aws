#
# Bucket used to store Bibash Gdrive backups
# Ref rclone
# pull: https://rclone.org/drive/
# push: https://rclone.org/s3/#amazon-s3
#
resource "aws_s3_bucket" "gdrive_backup" {
  bucket = "${var.project}-${var.environment}-gdrive-backup"
  acl    = "private"
  policy = data.aws_iam_policy_document.bucket_policy_gdrive_backup.json

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Enable lifecycle:
  #   - After 60 days, data is moved to Standard Infrequent Access
  #   - After 120 days, data is moved to Glacier
  lifecycle_rule {
    enabled = true

    transition {
      days          = 60
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }

    transition {
      days          = 120
      storage_class = "GLACIER"
    }
  }

  tags = local.tags
}

#
# S3 Enforce SSL Requests Bucket Policy
#
data "aws_iam_policy_document" "bucket_policy_gdrive_backup" {
  statement {
    sid = "EnforceSSlRequestsOnly"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.project}-${var.environment}-gdrive-backup/*"
    ]

    #
    # Check for a condition that always requires ssl communications
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
