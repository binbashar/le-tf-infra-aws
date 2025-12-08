locals {
  tags = {
    Name      = "${var.project}-${var.environment}-cloudtrail-org"
    Namespace = var.project
    Layer     = local.layer_name
  }
}
