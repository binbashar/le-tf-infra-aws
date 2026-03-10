# Bedrock Agent KYB - Fast Research
*Generated: 2025-01-06*

## Objective
Research AWS Bedrock Agent resources for implementing T-009 Bedrock Agent Configuration with 2 action groups (GetDocuments, SaveDocument) and session parameters support.

## Quick Findings

### Provider Comparison
- **AWSCC Provider (Preferred)**: `awscc_bedrock_agent` - Full-featured resource with comprehensive schema support
- **AWS Provider**: `aws_bedrockagent_agent`, `aws_bedrockagent_agent_action_group`, `aws_bedrockagent_agent_alias` - Traditional Terraform resources
- **Key Requirements**: Action groups, session parameters (runtime), IAM roles, OpenAPI schemas
- **Implementation Complexity**: Medium - Requires coordinating multiple resources and Lambda functions

### Essential Resources

#### 1. AWSCC Provider Resources (Recommended)
```hcl
# Main agent resource
resource "awscc_bedrock_agent" "kyb_agent" {
  agent_name              = local.agent_name
  foundation_model        = "anthropic.claude-v2:1"  # Or claude-3-sonnet-20240229-v1:0
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  instruction             = "You are a KYB document processing assistant..."

  idle_session_ttl_in_seconds = 600
  auto_prepare                = true

  action_groups = [
    {
      action_group_name = "GetDocuments"
      description       = "Retrieves processed documents from BDA output"
      api_schema = {
        payload = file("${path.module}/src/schemas/get_documents.yaml")
      }
      action_group_executor = {
        lambda = aws_lambda_function.get_documents.arn
      }
    },
    {
      action_group_name = "SaveDocument"
      description       = "Saves agent results to output bucket"
      api_schema = {
        s3 = {
          s3_bucket_name = aws_s3_bucket.processing.bucket
          s3_object_key  = "schemas/save_document.yaml"
        }
      }
      action_group_executor = {
        lambda = aws_lambda_function.save_document.arn
      }
    }
  ]
}
```

#### 2. AWS Provider Alternative
```hcl
# Main agent
resource "aws_bedrockagent_agent" "kyb_agent" {
  agent_name                  = local.agent_name
  foundation_model            = "anthropic.claude-v2"
  agent_resource_role_arn     = aws_iam_role.bedrock_agent.arn
  idle_session_ttl_in_seconds = 600
  instruction                 = "You are a KYB document processing assistant..."
}

# Action group for GetDocuments
resource "aws_bedrockagent_agent_action_group" "get_documents" {
  action_group_name = "GetDocuments"
  agent_id          = aws_bedrockagent_agent.kyb_agent.agent_id
  agent_version     = "DRAFT"

  action_group_executor {
    lambda = aws_lambda_function.get_documents.arn
  }

  api_schema {
    payload = file("${path.module}/src/schemas/get_documents.yaml")
  }
}

# Action group for SaveDocument
resource "aws_bedrockagent_agent_action_group" "save_document" {
  action_group_name = "SaveDocument"
  agent_id          = aws_bedrockagent_agent.kyb_agent.agent_id
  agent_version     = "DRAFT"

  action_group_executor {
    lambda = aws_lambda_function.save_document.arn
  }

  function_schema {
    member_functions {
      functions {
        name        = "save_document"
        description = "Saves processed document to output bucket"
        parameters {
          map_block_key = "content"
          type          = "string"
          description   = "Document content to save"
          required      = true
        }
      }
    }
  }
}
```

### Session Parameters Configuration

**IMPORTANT**: Session parameters are **runtime parameters**, not infrastructure configuration. They are passed when invoking the agent:

```python
# In Agent Invoker Lambda
response = bedrock_agent_runtime.invoke_agent(
    agentId=agent_id,
    agentAliasId=agent_alias_id,
    sessionId=session_id,
    inputText=input_text,
    sessionState={
        'sessionAttributes': {
            'correlation_id': correlation_id,
            'output_type': 'Standard',
            'customer_id': customer_id  # If needed
        },
        'promptSessionAttributes': {
            'processing_bucket': processing_bucket_name
        }
    }
)
```

### OpenAPI Schema Example
```yaml
openapi: 3.0.0
info:
  title: KYB Agent Actions
  version: 1.0.0
paths:
  /get-documents:
    post:
      operationId: getDocuments
      description: Retrieves processed documents from BDA output
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                document_type:
                  type: string
                  description: Type of document to retrieve
              required:
                - document_type
      responses:
        "200":
          description: Documents retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  documents:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                        content:
                          type: string
```

### IAM Role Requirements
```hcl
data "aws_iam_policy_document" "bedrock_agent_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "bedrock_agent_permissions" {
  statement {
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-v2*",
      "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-3*"
    ]
  }

  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.get_documents.arn,
      aws_lambda_function.save_document.arn
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.processing.arn,
      "${aws_s3_bucket.processing.arn}/*"
    ]
  }
}
```

## Key Implementation Considerations

### 1. Action Groups Configuration
- Action groups require either OpenAPI schema (recommended) or function schema
- Each action group needs a Lambda function executor
- Use `api_schema.payload` for inline YAML/JSON or `api_schema.s3` for S3-stored schemas
- `operationId` field is required for new models (Claude 3.5, Llama, etc.)

### 2. Session Parameters Behavior
- **sessionAttributes**: Persist across entire session (multiple InvokeAgent calls)
- **promptSessionAttributes**: Persist only for single turn
- Automatically passed to Lambda functions in action groups
- Used to avoid explicit parameter passing between agent and action groups

### 3. Standard Output Structure
- BDA standard output creates specific folder structure in processing bucket
- GetDocuments Lambda must understand this structure to retrieve files
- Path pattern: `{correlation_id}/standard_output/{document_type}/...`

### 4. Agent Preparation
- Set `auto_prepare = true` (AWSCC) or `prepare_agent = true` (AWS) for automatic preparation
- Agent must be prepared after creation or modification to be functional
- Preparation compiles the agent configuration and makes it ready for invocation

## Next Steps
1. Choose provider (AWSCC recommended for comprehensive features)
2. Create OpenAPI schemas for both action groups
3. Implement Lambda functions with session parameter handling
4. Configure IAM roles with appropriate permissions
5. Set up agent alias for versioning and deployment
6. Test with session parameters in Agent Invoker Lambda

## References
- [AWS Bedrock Agent Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Control Agent Session Context](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-session-state.html)
- [Define OpenAPI Schemas](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-api-schema.html)
- [AWSCC Provider Bedrock Agent](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrock_agent)
- [AWS Provider Bedrock Agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagent_agent)