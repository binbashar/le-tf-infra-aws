locals {
  environment = replace(var.environment, "apps-", "")
  name        = "${var.project}-${local.environment}-dynamodb"
  engine      = "dynamodb"

  tags = {
    Name        = local.name
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}