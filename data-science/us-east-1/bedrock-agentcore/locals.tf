locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = "bedrock-agentcore"
    Layer       = "bedrock-agentcore"
    Service     = "bedrock-agentcore"
  }

  name_prefix = lower(replace("${var.project}-${var.environment}-agentcore", "_", "-"))

  # AWSCC resource names must match ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  sanitized_name = replace(local.name_prefix, "-", "_")

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}
