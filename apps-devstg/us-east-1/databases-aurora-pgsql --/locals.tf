locals {
  environment = replace(var.environment, "apps-", "")
  name        = "${var.project}-${local.environment}-aurora-postgresql"
  engine      = "aurora-postgresql"

  tags = {
    Name               = local.name
    Terraform          = "true"
    Environment        = var.environment
  }
}
