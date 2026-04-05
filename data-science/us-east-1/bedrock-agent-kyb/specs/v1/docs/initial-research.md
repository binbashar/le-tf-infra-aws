# AWS Bedrock Agent Research Documentation

## Research Objective
Research how to create AWS Bedrock Agents using OpenTofu/Terraform modules, focusing on finding existing modules, understanding components, configuring action groups with Lambda functions, implementing IAM policies for S3 access, and integrating with the Leverage Reference Architecture.

## Research Plan
- [x] Step 1: Search for existing Terraform/OpenTofu modules for Bedrock Agents
- [x] Step 2: Understand basic components needed for a Bedrock Agent
- [x] Step 3: Research action groups and Lambda integration patterns
- [x] Step 4: Document IAM policies required for S3 access
- [x] Step 5: Analyze Leverage architecture integration patterns
- [x] Step 6: Compile comprehensive research findings

## Key Findings

### AWS Service Documentation

#### Bedrock Agent Core Components
AWS Bedrock Agents enable generative AI applications to execute multistep tasks across company systems and data sources. Key components include:

1. **Foundation Model**: The LLM that powers the agent (e.g., `anthropic.claude-v2`, `anthropic.claude-3-5-sonnet`)
2. **Agent Instructions**: Natural language instructions defining the agent's behavior
3. **Action Groups**: Define functions the agent can call (Lambda functions)
4. **Knowledge Bases**: Optional RAG data sources for contextual information
5. **Agent Alias**: Deployment version for production use
6. **Service Role**: IAM role with permissions to invoke models and access resources

#### AWSCC Provider Support
The AWSCC provider offers comprehensive Bedrock Agent support through `awscc_bedrock_agent` resource with:
- Full action group configuration including Lambda executors
- API schema support (OpenAPI or function definitions)
- Knowledge base associations
- Memory configuration for conversation context
- Guardrail integration for content filtering
- Multi-agent collaboration support

### OpenTofu/Terraform Modules

#### 1. Official AWS-IA Module: `aws-ia/bedrock/aws`
**Version**: 0.0.29 (latest as of research)
**Repository**: https://github.com/aws-ia/terraform-aws-bedrock

Key Features:
- Comprehensive Bedrock Agent creation and management
- Action group support with Lambda integration
- Knowledge base creation (OpenSearch, Neptune, MongoDB, Pinecone, RDS)
- Guardrails for content filtering
- Multi-agent collaboration
- Prompt management and versioning
- Custom model support
- Bedrock Data Automation (BDA) projects

Example minimal configuration:
```hcl
module "bedrock_agent" {
  source           = "aws-ia/bedrock/aws"
  version          = "0.0.29"
  foundation_model = "anthropic.claude-v2"
  instruction      = "You are an assistant that helps with document processing"

  # Enable action group
  create_ag = true
  action_group_name = "document_processor"
  lambda_action_group_executor = aws_lambda_function.processor.arn
  api_schema_s3_bucket_name = aws_s3_bucket.schemas.bucket
  api_schema_s3_object_key = "openapi-schema.json"
}
```

#### 2. Community Modules

**sourcefuse/terraform-aws-arc-bedrock**
- Flexible and reusable module for Bedrock Agents
- Supports collaborators and action groups
- Automated IAM role creation

**acwwat/terraform-amazon-bedrock-agent-example**
- Example implementations with complete patterns
- Includes data ingestion solutions

### Implementation Considerations

#### Action Groups with Lambda Functions

Action groups define the APIs your agent can invoke. Configuration requires:

1. **OpenAPI Schema or Function Details**:
   - OpenAPI: JSON/YAML schema stored in S3
   - Function Details: Direct parameter definitions

2. **Lambda Function Configuration**:
   ```python
   # Lambda input event structure
   {
       "messageVersion": "1.0",
       "agent": {
           "name": "string",
           "id": "string",
           "alias": "string",
           "version": "string"
       },
       "actionGroup": "string",
       "apiPath": "string",  # For API schema
       "function": "string", # For function details
       "parameters": [...],
       "requestBody": {...}
   }

   # Lambda response structure
   {
       "messageVersion": "1.0",
       "response": {
           "actionGroup": "string",
           "apiPath": "string",
           "httpMethod": "string",
           "httpStatusCode": 200,
           "responseBody": {
               "application/json": {
                   "body": "json_string"
               }
           }
       }
   }
   ```

3. **Lambda Resource-Based Policy**:
   ```json
   {
       "Effect": "Allow",
       "Principal": {
           "Service": "bedrock.amazonaws.com"
       },
       "Action": "lambda:InvokeFunction",
       "Condition": {
           "StringEquals": {
               "AWS:SourceAccount": "123456789012"
           },
           "ArnLike": {
               "AWS:SourceArn": "arn:aws:bedrock:*:123456789012:agent/*"
           }
       }
   }
   ```

### Security & Compliance

#### IAM Policies for S3 Access

1. **Agent Service Role Trust Policy**:
```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Service": "bedrock.amazonaws.com"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
            "StringEquals": {
                "aws:SourceAccount": "123456789012"
            },
            "ArnLike": {
                "AWS:SourceArn": "arn:aws:bedrock:us-east-1:123456789012:agent/*"
            }
        }
    }]
}
```

2. **S3 Permissions for Action Group Schemas**:
```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "AgentActionGroupS3",
        "Effect": "Allow",
        "Action": ["s3:GetObject"],
        "Resource": ["arn:aws:s3:::bucket-name/schema-path/*"],
        "Condition": {
            "StringEquals": {
                "aws:ResourceAccount": "123456789012"
            }
        }
    }]
}
```

3. **S3 Permissions for Code Interpretation/File Access**:
```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "AmazonBedrockAgentFileAccess",
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetObjectVersionAttributes",
            "s3:GetObjectAttributes",
            "s3:PutObject"  # If agent needs write access
        ],
        "Resource": ["arn:aws:s3:::data-bucket/*"]
    }]
}
```

4. **Lambda Execution Role for Action Groups**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3Access",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::input-bucket/*",
                "arn:aws:s3:::output-bucket/*"
            ]
        }
    ]
}
```

### Cost Implications

1. **Model Invocation Costs**:
   - Claude v2: ~$0.008 per 1K input tokens, $0.024 per 1K output tokens
   - Claude 3.5 Sonnet: Higher pricing tier
   - Consider using cheaper models for development/testing

2. **Lambda Costs**:
   - Invocations: $0.20 per 1M requests
   - Duration: Based on memory allocation
   - Consider timeout settings and memory optimization

3. **Storage Costs**:
   - S3 for schemas and data: Standard S3 pricing
   - OpenSearch Serverless (if using KB): ~$0.24/hr per OCU
   - CloudWatch Logs: $0.50 per GB ingested

### Integration Points

#### Leverage Architecture Integration

Based on existing `data-science/us-east-1/bedrock-kyb-bda` layer analysis:

1. **Layer Structure**:
```
data-science/us-east-1/bedrock-agent/
├── config.tf                    # Provider and backend configuration
├── common-variables.tf          # Symlinked shared variables
├── locals.tf                    # Local value calculations
├── variables.tf                 # Layer-specific variables
├── outputs.tf                   # Output definitions
├── agent.tf                     # Bedrock Agent resources
├── iam.tf                       # IAM roles and policies
├── lambda.tf                    # Action group Lambda functions
├── s3.tf                        # S3 buckets for data/schemas
└── src/                         # Lambda function source code
    └── action-handler/
        └── lambda_function.py
```

2. **Backend Configuration**:
   - Use existing S3 backend pattern
   - State path: `data-science/bedrock-agent/terraform.tfstate`

3. **Naming Conventions**:
   - Resources: `bb-${var.environment}-bedrock-agent-{resource}`
   - Lambda: `bb-${var.environment}-bedrock-agent-handler`
   - S3 buckets: `bb-${var.environment}-bedrock-agent-{input|output}`

4. **Cross-Layer Dependencies**:
   - KMS keys from `security/keys` layer
   - VPC/Subnets from `network` layer (if Lambda in VPC)
   - Existing S3 buckets from other layers

## Recommended Approach

### 1. Use AWS-IA Module
The `aws-ia/bedrock/aws` module (v0.0.29) provides the most comprehensive and maintained solution for Bedrock Agents. It supports all required features and follows AWS best practices.

### 2. Layer Implementation Strategy
```hcl
# data-science/us-east-1/bedrock-agent/agent.tf
module "bedrock_agent" {
  source  = "aws-ia/bedrock/aws"
  version = "0.0.29"

  # Core agent configuration
  agent_name       = local.agent_name
  foundation_model = var.foundation_model
  instruction      = var.agent_instruction

  # Action group configuration
  create_ag                    = true
  action_group_name           = "${local.agent_name}-actions"
  lambda_action_group_executor = aws_lambda_function.action_handler.arn
  api_schema_s3_bucket_name   = aws_s3_bucket.schemas.bucket
  api_schema_s3_object_key    = "openapi/agent-schema.json"

  # Optional: Enable agent alias for production
  create_agent_alias = var.create_alias
  agent_alias_name   = "${local.agent_name}-${var.environment}"

  # IAM configuration
  agent_resource_role_arn = aws_iam_role.agent_role.arn

  # Encryption
  kms_key_arn = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  tags = local.tags
}
```

### 3. Action Group Lambda Pattern
```python
# src/action-handler/lambda_function.py
import json
import boto3

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """Handle Bedrock Agent action group invocations"""

    message_version = event.get('messageVersion', '1.0')
    action_group = event.get('actionGroup')
    api_path = event.get('apiPath')
    parameters = event.get('parameters', [])

    # Route to appropriate handler based on API path
    if api_path == '/process-document':
        result = process_document(parameters)
    elif api_path == '/extract-data':
        result = extract_data(parameters)
    else:
        result = {"error": "Unknown API path"}

    # Return properly formatted response
    return {
        "messageVersion": message_version,
        "response": {
            "actionGroup": action_group,
            "apiPath": api_path,
            "httpMethod": "POST",
            "httpStatusCode": 200,
            "responseBody": {
                "application/json": {
                    "body": json.dumps(result)
                }
            }
        }
    }
```

### 4. Minimal Configuration for Basic Agent
For a basic agent without Knowledge Base:
1. Use the AWS-IA module with minimal parameters
2. Define one action group with 2-3 core functions
3. Implement Lambda handler for action processing
4. Configure S3 buckets for input/output data
5. Set up appropriate IAM roles with least privilege

## References

### Official Documentation
- [AWS Bedrock Agents Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [AWS Bedrock Agent Permissions](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-permissions.html)
- [AWS Bedrock Action Groups](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-action-add.html)
- [Lambda Functions for Agents](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-lambda.html)
- [AWSCC Provider Bedrock Agent Resource](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrock_agent)

### Terraform/OpenTofu Modules
- [AWS-IA Bedrock Module](https://github.com/aws-ia/terraform-aws-bedrock)
- [Terraform Registry - aws-ia/bedrock/aws](https://registry.terraform.io/modules/aws-ia/bedrock/aws/latest)
- [SourceFuse Bedrock Module](https://github.com/sourcefuse/terraform-aws-arc-bedrock)

### Example Implementations
- [AWS Generative AI Terraform Samples](https://github.com/aws-samples/aws-generative-ai-terraform-samples)
- [Bedrock Multi-Agent Orchestrator](https://github.com/aws-samples/amazon-bedrock-multiagent-orchestrator-terraform)
- [Intelligent RAG Bedrock Agent IaC](https://github.com/aws-samples/intelligent-rag-bedrockagent-iac)

### Blog Posts and Tutorials
- [AWS Blog: Automated Deployment with Agent Lifecycle](https://aws.amazon.com/blogs/infrastructure-and-automation/build-an-automated-deployment-of-generative-ai-with-agent-lifecycle-changes-using-terraform/)
- [Managing Bedrock Agents with Terraform](https://blog.avangards.io/how-to-manage-an-amazon-bedrock-agent-using-terraform)