#------------------------------------------------------------------------------
# Velero Backups
#------------------------------------------------------------------------------
resource "helm_release" "velero" {
  name       = "velero"
  namespace  = kubernetes_namespace.velero.id
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "2.21.0"
  values = [
    templatefile("chart-values/velero.yaml",
      {
        bucket = aws_s3_bucket.valero_s3.id
      }
    )
  ]
}

#------------------------------------------------------------------------------
# Velero S3 Storage
#------------------------------------------------------------------------------
# Buckets
resource "aws_s3_bucket" "valero_s3" {
  name = "le-${var.environment}-valero"
  acl  = "private"
}
