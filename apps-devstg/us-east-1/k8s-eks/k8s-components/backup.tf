#------------------------------------------------------------------------------
# Velero Backups
#------------------------------------------------------------------------------
resource "helm_release" "velero" {
  count      = var.enable_backups ? 1 : 0
  name       = "velero"
  namespace  = kubernetes_namespace.velero[0].id
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "2.21.0"
  values = [
    templatefile("chart-values/velero.yaml",
      {
        bucket    = aws_s3_bucket.velero_s3[0].id
        iam_role  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/velero-backups"
        schedules = var.schedules
      }
    )
  ]
}

#------------------------------------------------------------------------------
# Velero S3 Storage
#------------------------------------------------------------------------------
# Buckets
resource "aws_s3_bucket" "velero_s3" {
  count  = var.enable_backups ? 1 : 0
  bucket = "le-${var.environment}-velero"
}

resource "aws_s3_bucket_versioning" "velero_s3_versioning" {
  count  = var.enable_backups ? 1 : 0
  bucket = aws_s3_bucket.velero_s3[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "velero_s3_acl" {
  count  = var.enable_backups ? 1 : 0
  bucket = aws_s3_bucket.velero_s3[0].id
  acl    = "private"
}
