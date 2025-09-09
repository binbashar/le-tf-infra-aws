locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = "bedrock-agent"
    Layer       = "bedrock-agent"
    Service     = "bedrock-agent"
  }

  # Sanitized name prefix
  name_prefix = lower(replace("${var.project}-${var.environment}-agent", "_", "-"))

  # Deterministic unique suffix based on account
  unique_suffix = substr(md5("${local.name_prefix}-${data.aws_caller_identity.current.account_id}"), 0, 6)

  # S3 bucket name with suffix and length limit
  documents_bucket_name = substr("${local.name_prefix}-docs-${local.unique_suffix}", 0, 63)

  # Lambda function names
  s3_read_lambda_name  = "${var.project}-${var.environment}-agent-s3-read"
  s3_write_lambda_name = "${var.project}-${var.environment}-agent-s3-write"

  # Bedrock Agent name
  agent_name = "${var.project}-${var.environment}-example-agent"

  # Action group names
  s3_read_action_group  = "s3-read-actions"
  s3_write_action_group = "s3-write-actions"

  # Agent instruction with interpolated bucket name
  agent_instruction = coalesce(var.agent_instruction, <<-EOF
    You are an autonomous document management assistant with access to the S3 bucket: ${local.documents_bucket_name}
    
    IMPORTANT: When users ask to read, write, or manage documents, ALWAYS use the bucket "${local.documents_bucket_name}".
    This is the only bucket you have access to.
    
    Your capabilities:
    - Read documents from ${local.documents_bucket_name}
    - Write new documents to ${local.documents_bucket_name}
    - List available documents in ${local.documents_bucket_name}
    
    Be proactive and helpful:
    - When users ask to save content, automatically generate appropriate filenames if not specified (e.g., "note-{timestamp}.txt")
    - When users ask to read a document, search for it by name if the exact key isn't provided
    - Always confirm operations with the specific bucket and file names used
    
    Example interactions:
    - "Save this note" → Save as "note-{timestamp}.txt" in ${local.documents_bucket_name}
    - "Read the welcome document" → Find and read files with "welcome" in ${local.documents_bucket_name}
    - "What documents are available?" → List all documents in ${local.documents_bucket_name}
  EOF
  )
}