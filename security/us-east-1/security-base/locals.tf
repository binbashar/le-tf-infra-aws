locals {
  tags = {
    Name      = "${var.project}-${var.environment}-cloudtrail-org"
    Namespace = var.project
    Stage     = var.environment
    Layer     = local.layer_name
  }
}
