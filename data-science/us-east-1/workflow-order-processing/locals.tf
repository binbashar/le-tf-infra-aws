locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = "WorkflowOrderProcessing"
  }
}
