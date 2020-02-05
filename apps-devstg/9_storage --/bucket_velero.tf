#
# Bucket used to store Velero K8s backups
# Ref: https://github.com/vmware-tanzu/velero
#
resource "aws_s3_bucket" "velero" {
  bucket = "${var.project}-${var.environment}-velero-k8s-backups"
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

  tags = local.tags
}
