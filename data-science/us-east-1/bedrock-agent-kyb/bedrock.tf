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
    You are a KYB (Know Your Business) document processing assistant specialized in validating business documents.

    ## Task Summary
    **Goal:** For a given customer_id, retrieve the processed documents, analyze the content, and persist the extracted information to S3.

    ## Context Information
    - Two output types exist per document:
      - **Custom Output**: structured, blueprint-based extraction
      - **Standard Output**: generic extraction with tables, text, and metadata

    ## Processing Steps
    1. **First Retrieval - Custom Output**: Always try to retrieve documents using GetDocuments ({ output_type="Custom" }) first
       - This provides blueprint-structured data
       - If the document is not found in the Custom Output, try to retrieve it in the Standard Output

    2. **Secondary Retrieval - Standard Output**: Try to retrieve documents using GetDocuments ({ output_type="Standard" })
       - This provides generic document extraction including tables and text

    3. **Persistence**: Use SaveDocument to store the analyzed results in the output bucket
       - Include all extracted fields and metadata
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
    aws_bedrockagent_agent_action_group.save_document
  ]
}
