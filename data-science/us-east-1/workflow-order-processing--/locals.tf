locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Project      = "WorkflowOrderProcessing"
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }
}
