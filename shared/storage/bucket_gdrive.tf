#
# Bucket used to store Bibash Gdrive backups
# Ref rclone
# pull: https://rclone.org/drive/
# push: https://rclone.org/s3/#amazon-s3
#
resource "aws_s3_bucket" "gdrive" {
  bucket = "${var.project}-${var.environment}-gdrive-backup"
  acl    = "private"

  versioning {
    enabled = true
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
