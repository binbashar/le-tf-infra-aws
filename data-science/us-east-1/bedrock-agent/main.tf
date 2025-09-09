#================================
# Bedrock Agent Module
#================================

module "bedrock_agent" {
  source  = "aws-ia/bedrock/aws"
  version = "0.0.29"

  # Core agent configuration
  agent_name = local.agent_name
  # Use configurable foundation model
  foundation_model = var.foundation_model
  instruction      = local.agent_instruction

  # IAM configuration - let module create the role 
  agent_resource_role_arn = null

  # Create agent without action groups first
  action_group_list = []
  create_ag         = false

  create_agent_alias = false

  # Encryption configuration
  kms_key_arn = var.enable_encryption ? data.terraform_remote_state.keys.outputs.aws_kms_key_arn : null

  # Disable knowledge base
  create_kb = false

  tags = local.tags

  depends_on = [
    aws_lambda_function.s3_read,
    aws_lambda_function.s3_write,
    aws_lambda_permission.allow_bedrock_s3_read,
    aws_lambda_permission.allow_bedrock_s3_write
  ]
}

#===================
# Agent Preparation
#===================

resource "null_resource" "prepare_agent" {
  provisioner "local-exec" {
    command = "aws bedrock-agent prepare-agent --agent-id ${module.bedrock_agent.bedrock_agent[0].agent_id} --region ${var.region} --profile ${var.profile}"
  }

  depends_on = [module.bedrock_agent]

  triggers = {
    agent_id = module.bedrock_agent.bedrock_agent[0].agent_id
  }
}

#===================
# Agent Cleanup on Destroy
#===================

# Orchestrated cleanup that handles the entire deletion sequence
resource "null_resource" "orchestrated_cleanup" {
  # Store only module output in triggers (no circular dependency)
  triggers = {
    agent_id = try(module.bedrock_agent.bedrock_agent[0].agent_id, "")
    region   = var.region
    profile  = var.profile
  }

  # Run cleanup script on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/cleanup-agent.sh"
    environment = {
      AGENT_ID      = self.triggers.agent_id
      # Empty action groups - script will find them dynamically
      ACTION_GROUPS = "[]"
      AWS_REGION    = self.triggers.region
      AWS_PROFILE   = self.triggers.profile
      FIND_GROUPS   = "true"  # Tell script to find action groups
    }
  }
}

resource "aws_bedrockagent_agent_action_group" "s3_read" {
  action_group_name          = "s3-read-actions"
  agent_id                   = module.bedrock_agent.bedrock_agent[0].agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  prepare_agent              = false
  
  action_group_executor {
    lambda = aws_lambda_function.s3_read.arn
  }
  api_schema {
    payload = file("${path.module}/schemas/s3-read.yaml")
  }

  depends_on = [null_resource.orchestrated_cleanup]

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_bedrockagent_agent_action_group" "s3_write" {
  action_group_name          = "s3-write-actions"
  agent_id                   = module.bedrock_agent.bedrock_agent[0].agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  prepare_agent              = false
  
  action_group_executor {
    lambda = aws_lambda_function.s3_write.arn
  }
  api_schema {
    payload = file("${path.module}/schemas/s3-write.yaml")
  }

  depends_on = [null_resource.orchestrated_cleanup]

  lifecycle {
    create_before_destroy = false
  }
}