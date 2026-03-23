resource "awscc_bedrock_data_automation_project" "kyb_agent" {
  project_name        = local.bda_project_name
  project_description = "BDA project for KYB agent document processing"

  standard_output_configuration = {
    document = {
      extraction = {
        bounding_box = {
          state = "DISABLED"
        }
        granularity = {
          types = ["DOCUMENT", "PAGE", "ELEMENT"]
        }
      }
      generative_field = {
        state = "ENABLED"
      }
      output_format = {
        additional_file_format = {
          state = "ENABLED"
        }
        text_format = {
          types = ["PLAIN_TEXT", "MARKDOWN", "CSV"]
        }
      }
    }
  }

  tags = [
    for key, value in local.tags : {
      key   = key
      value = value
    }
  ]
}

#================================
# Bedrock Agent
#================================

resource "awscc_bedrock_agent" "kyb_agent" {
  agent_name              = local.agent_name
  description             = "KYB document processing agent with BDA integration"
  foundation_model        = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
  agent_resource_role_arn = aws_iam_role.bedrock_agent_role.arn

  instruction = <<-EOT
    You are a KYB (Know Your Business) compliance agent responsible for analyzing company documents and verifying that company representatives are not subject to sanctions or politically exposed person (PEP) risks.

    ## Document Analysis
    1. Retrieve all documents using GetDocuments action group (try Custom output first, then Standard output)
    2. Identify company representatives (directors, legal representatives, beneficial owners)
    3. Extract name, surname, and document ID for each representative

    ## Sanctions Verification
    1. For each representative, use CheckSanctions action group
    2. Pass name+surname OR document_id to CheckSanctions
    3. Evaluate results: num_sanctions and pep_score

    ## Decision Logic
    - APPROVED: All representatives identified AND all have num_sanctions=0 AND pep_score<0.7
    - REJECTED: Any representative has num_sanctions>0 OR pep_score>=0.7
    - REVIEW_REQUIRED: Cannot identify representatives OR insufficient information

    ## Persistence
    Use SaveDocument to save verdict with representatives data and decision rationale
  EOT

  idle_session_ttl_in_seconds = 600
  auto_prepare                = true

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.bedrock_agent_policy,
    aws_lambda_function.get_documents,
    aws_lambda_function.save_document
  ]
}

#================================
# Agent Action Groups
#================================

resource "aws_bedrockagent_agent_action_group" "get_documents" {
  action_group_name          = "GetDocuments"
  agent_id                   = awscc_bedrock_agent.kyb_agent.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  prepare_agent              = false
  description                = "Retrieves processed documents from BDA output folder in processing bucket"

  action_group_executor {
    lambda = aws_lambda_function.get_documents.arn
  }

  api_schema {
    payload = file("${path.module}/src/schemas/get_documents.yaml")
  }

  depends_on = [
    awscc_bedrock_agent.kyb_agent,
    aws_lambda_permission.allow_bedrock_get_documents
  ]
}

resource "aws_bedrockagent_agent_action_group" "save_document" {
  action_group_name          = "SaveDocument"
  agent_id                   = awscc_bedrock_agent.kyb_agent.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  prepare_agent              = false
  description                = "Saves agent-processed results to output bucket with metadata"

  action_group_executor {
    lambda = aws_lambda_function.save_document.arn
  }

  api_schema {
    payload = file("${path.module}/src/schemas/save_document.yaml")
  }

  depends_on = [
    awscc_bedrock_agent.kyb_agent,
    aws_lambda_permission.allow_bedrock_save_document
  ]
}

resource "aws_bedrockagent_agent_action_group" "check_sanctions" {
  action_group_name          = "CheckSanctions"
  agent_id                   = awscc_bedrock_agent.kyb_agent.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  prepare_agent              = false
  description                = "Checks external sanctions API for PEP and sanctions verification"

  action_group_executor {
    lambda = aws_lambda_function.check_sanctions.arn
  }

  api_schema {
    payload = file("${path.module}/src/schemas/check_sanctions.yaml")
  }

  depends_on = [
    awscc_bedrock_agent.kyb_agent,
    aws_lambda_permission.allow_bedrock_check_sanctions
  ]
}

#================================
# Agent Alias
#================================

resource "awscc_bedrock_agent_alias" "kyb_agent_live" {
  agent_alias_name = "live"
  agent_id         = awscc_bedrock_agent.kyb_agent.agent_id
  description      = "Live alias for KYB agent"

  tags = local.tags

  depends_on = [
    awscc_bedrock_agent.kyb_agent,
    aws_bedrockagent_agent_action_group.get_documents,
    aws_bedrockagent_agent_action_group.save_document,
    aws_bedrockagent_agent_action_group.check_sanctions
  ]
}
