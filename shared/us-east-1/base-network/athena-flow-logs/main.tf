locals {
  tags = {
    Name        = "athena-flow-logs"
    Terraform   = "true"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# RDS Export To S3
# -----------------------------------------------------------------------------
module "athena_flow_logs" {
  source = "./terraform-aws-athena-flow-logs"

  prefix                      = "${var.project}-${var.environment}"
  create_query_results_bucket = true

  tags = local.tags
}
