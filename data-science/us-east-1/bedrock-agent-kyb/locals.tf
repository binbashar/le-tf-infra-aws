locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = "bedrock-kyb-agent"
    Layer       = "bedrock-kyb-agent"
    Service     = "bedrock-data-automation-agent"
  }

  name_prefix = lower(replace("${var.project}-${var.environment}-kyb-agent", "_", "-"))

  unique_suffix = substr(md5("${local.name_prefix}-${data.aws_caller_identity.current.account_id}"), 0, 6)

  input_bucket_name      = substr("${local.name_prefix}-input-${local.unique_suffix}", 0, 63)
  processing_bucket_name = substr("${local.name_prefix}-processing-${local.unique_suffix}", 0, 63)
  output_bucket_name     = substr("${local.name_prefix}-output-${local.unique_suffix}", 0, 63)

  bda_invoker_name   = "${var.project}-${var.environment}-kyb-agent-bda-invoker"
  agent_invoker_name = "${var.project}-${var.environment}-kyb-agent-invoker"
  get_documents_name = "${var.project}-${var.environment}-kyb-agent-get-docs"
  save_document_name = "${var.project}-${var.environment}-kyb-agent-save-doc"

  bda_project_name = "${var.project}-${var.environment}-kyb-agent-bda"
  agent_name       = "${var.project}-${var.environment}-kyb-agent"

  input_rule_name      = "${var.project}-${var.environment}-kyb-agent-input-trigger"
  processing_rule_name = "${var.project}-${var.environment}-kyb-agent-processing-trigger"
}