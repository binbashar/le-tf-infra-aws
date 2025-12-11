locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  # EventBridge Scheduler Configuration
  scheduler_role_name      = "${var.project}-${var.environment}-scheduler-mwaa-role"
  mwaa_execution_role_name = "${var.project}-${var.environment}-mwaa-execution-role"
  mwaa_execution_role_arn  = module.iam_assumable_role_mwaa_execution.iam_role_arn
}
