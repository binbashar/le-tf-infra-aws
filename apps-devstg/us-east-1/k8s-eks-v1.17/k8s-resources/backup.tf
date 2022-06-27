#------------------------------------------------------------------------------
# Velero Backups
#------------------------------------------------------------------------------
# resource "helm_release" "velero" {
#   name       = "velero"
#   count      = var.enable_backups ? 1 : 0
#   namespace  = kubernetes_namespace.velero.id
#   repository = "https://vmware-tanzu.github.io/helm-charts"
#   chart      = "velero"
#   version    = "2.21.0"
#   values = [
#     templatefile("chart-values/velero.yaml",
#       {
#         bucket    = aws_s3_bucket.velero_s3.id
#         iam_role  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/velero-backups"
#         schedules = var.schedules
#       }
#     )
#   ]
# }

#------------------------------------------------------------------------------
# Velero S3 Storage
#------------------------------------------------------------------------------
# Buckets
# resource "aws_s3_bucket" "velero_s3" {
#   bucket = "le-${var.environment}-velero"
#   acl    = "private"

#   versioning {
#     enabled = true
#   }

# }
