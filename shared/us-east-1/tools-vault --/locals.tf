resource "random_uuid" "bucket_name_suffix" {}

locals {
  bucket_name             = "${var.project}-${var.environment}-vault-${random_uuid.bucket_name_suffix.result}"
  destination_bucket_name = "${local.bucket_name}-replica"

  tags = {
    Name               = "${var.prefix}-${var.name}"
    Terraform          = "true"
    Environment        = var.environment
    ScheduleStopDaily  = false
    ScheduleStartDaily = false
    Backup             = "True"
    Layer              = local.layer_name
  }
}
