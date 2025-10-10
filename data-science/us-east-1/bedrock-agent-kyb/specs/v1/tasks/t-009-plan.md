# T-009: Bedrock Agent Configuration - Detailed Plan

**Last Updated:** 2025-01-09
**Revision:** 2.0 - Updated for cross-region inference profiles and corrected session parameter architecture

## Overview
Implement Bedrock Agent infrastructure with 2 action groups (GetDocuments, SaveDocument) following minimal implementation principles. Uses AWSCC provider for comprehensive feature support, cross-region inference profiles for high availability, and session parameters for customer context passing.

## Execution Strategy
Execute subtasks **sequentially** in the order listed below. Each subtask must complete and validate before moving to the next.

---

## Subtask Breakdown

### T-009.1: Create OpenAPI schemas for action groups

**Purpose**: Define action group interfaces for GetDocuments and SaveDocument operations

**Actions**:
1. Create schemas directory: `src/schemas/`
2. Create `src/schemas/get_documents.yaml`:
   ```yaml
   openapi: 3.0.0
   info:
     title: GetDocuments Action
     version: 1.0.0
     description: Retrieves processed documents from BDA standard output
   paths:
     /documents:
       get:
         operationId: getDocuments
         description: Retrieves customer-specific documents from processing bucket
         parameters:
           - name: output_type
             in: query
             required: true
             schema:
               type: string
               enum: [Standard, Custom]
               default: Standard
             description: BDA output type determining folder structure (Standard or Custom)
           - name: key_pattern
             in: query
             required: false
             schema:
               type: string
             description: Optional S3 key pattern filter
         responses:
           "200":
             description: Documents retrieved successfully
             content:
               application/json:
                 schema:
                   type: object
                   properties:
                     customer_id:
                       type: string
                       description: Customer identifier from session
                     output_type:
                       type: string
                       description: BDA output type used
                     documents:
                       type: array
                       items:
                         type: object
                         properties:
                           s3_key:
                             type: string
                           last_modified:
                             type: string
                           document_text:
                             type: string
   ```

3. Create `src/schemas/save_document.yaml`:
   ```yaml
   openapi: 3.0.0
   info:
     title: SaveDocument Action
     version: 1.0.0
     description: Saves agent-processed results to output bucket
   paths:
     /documents:
       post:
         operationId: saveDocument
         description: Saves processed document results with metadata
         requestBody:
           required: true
           content:
             application/json:
               schema:
                 type: object
                 properties:
                   content:
                     type: string
                     description: Processed document content
                   document_key:
                     type: string
                     description: S3 key for the document
                 required:
                   - content
                   - document_key
         responses:
           "200":
             description: Document saved successfully
             content:
               application/json:
                 schema:
                   type: object
                   properties:
                     status:
                       type: string
                     s3_key:
                       type: string
   ```

**Pattern Reference**: OpenAPI 3.0.0 format with `operationId` required for newer models

**Key Requirements**:
- Must include `operationId` field for each path (required for Claude 3.5+, Llama, Nova models)
- Schema defines action group parameters (e.g., output_type) - these are NOT session parameters
- Session parameters (ONLY customer_id) come from Agent Invoker Lambda
- Action group parameters (output_type, key_pattern) come from OpenAPI schema definitions
- Lambda receives both sources combined in the event structure

**Validation**: Valid OpenAPI 3.0.0 YAML syntax, includes operationId

---

### T-009.2: Create IAM role for Bedrock Agent

**Purpose**: Define service role for agent with required permissions

**Actions**:
1. Add to `iam.tf`:

   **A. Trust Policy**:
   ```hcl
   data "aws_iam_policy_document" "bedrock_agent_trust" {
     statement {
       effect = "Allow"
       principals {
         type        = "Service"
         identifiers = ["bedrock.amazonaws.com"]
       }
       actions = ["sts:AssumeRole"]

       condition {
         test     = "StringEquals"
         variable = "aws:SourceAccount"
         values   = [data.aws_caller_identity.current.account_id]
       }

       condition {
         test     = "ArnLike"
         variable = "aws:SourceArn"
         values   = ["arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"]
       }
     }
   }
   ```

   **B. Permissions Policy**:
   ```hcl
   data "aws_iam_policy_document" "bedrock_agent_permissions" {
     statement {
       sid    = "BedrockModelAccess"
       effect = "Allow"
       actions = [
         "bedrock:InvokeModel",
         "bedrock:InvokeModelWithResponseStream"
       ]
       resources = [
         "arn:aws:bedrock:${var.region}::foundation-model/*",
         "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/*"
       ]
     }

     statement {
       sid    = "ActionGroupLambdaAccess"
       effect = "Allow"
       actions = ["lambda:InvokeFunction"]
       resources = [
         aws_lambda_function.get_documents.arn,
         aws_lambda_function.save_document.arn
       ]
     }
   }
   ```

   **C. IAM Role**:
   ```hcl
   resource "aws_iam_role" "bedrock_agent_role" {
     name               = "${local.agent_name}-role"
     assume_role_policy = data.aws_iam_policy_document.bedrock_agent_trust.json
     tags               = local.tags
   }
   ```

   **D. IAM Policy**:
   ```hcl
   resource "aws_iam_policy" "bedrock_agent_policy" {
     name   = "${local.agent_name}-policy"
     policy = data.aws_iam_policy_document.bedrock_agent_permissions.json
     tags   = local.tags
   }
   ```

   **E. Policy Attachment**:
   ```hcl
   resource "aws_iam_role_policy_attachment" "bedrock_agent_policy" {
     role       = aws_iam_role.bedrock_agent_role.name
     policy_arn = aws_iam_policy.bedrock_agent_policy.arn
   }
   ```

**Pattern Reference**: `/data-science/us-east-1/bedrock-agent-kyb/iam.tf` (data source pattern)

**Key Permissions**:
- **Bedrock Model Access**: InvokeModel for all foundation models and inference profiles
- **Inference Profile Support**: Wildcard resources for both foundation-model and inference-profile ARNs
- **Lambda Functions**: InvokeFunction for both action groups (GetDocuments, SaveDocument)
- **Trust Policy**: bedrock.amazonaws.com with account/ARN conditions for security

**Validation**: IAM resources defined following data source pattern

---

### T-009.3: Add Bedrock Agent resource to bedrock.tf

**Purpose**: Create agent with action groups using AWSCC provider

**Actions**:
1. Add to existing `bedrock.tf` file:

```hcl
resource "awscc_bedrock_agent" "kyb_agent" {
  agent_name              = local.agent_name
  description             = "KYB document processing agent with BDA integration"
  foundation_model        = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
  agent_resource_role_arn = aws_iam_role.bedrock_agent_role.arn

  instruction = <<-EOT
    You are a KYB (Know Your Business) document processing assistant that helps retrieve and analyze business documents.

    When invoked:
    1. Use the GetDocuments action to retrieve documents from the processing bucket for the specified customer
    2. Review the retrieved documents
    3. Extract relevant information based on the request
    4. Use the SaveDocument action to save your analysis to the output bucket
  EOT

  idle_session_ttl_in_seconds = 600
  auto_prepare                = true

  action_groups = [
    {
      action_group_name = "GetDocuments"
      description       = "Retrieves processed documents from BDA standard output in processing bucket"
      action_group_state = "ENABLED"

      api_schema = {
        payload = file("${path.module}/src/schemas/get_documents.yaml")
      }

      action_group_executor = {
        lambda = aws_lambda_function.get_documents.arn
      }
    },
    {
      action_group_name = "SaveDocument"
      description       = "Saves agent-processed results to output bucket with metadata"
      action_group_state = "ENABLED"

      api_schema = {
        payload = file("${path.module}/src/schemas/save_document.yaml")
      }

      action_group_executor = {
        lambda = aws_lambda_function.save_document.arn
      }
    }
  ]

  tags = [
    for key, value in local.tags : {
      key   = key
      value = value
    }
  ]

  depends_on = [
    aws_iam_role_policy_attachment.bedrock_agent_policy,
    aws_lambda_function.get_documents,
    aws_lambda_function.save_document
  ]
}
```

**Pattern Reference**: AWSCC provider pattern from research document

**Key Configuration**:
- **Foundation Model**: Cross-region inference profile `us.anthropic.claude-sonnet-4-5-20250929-v1:0`
- **Inference Profile Benefits**: Automatic failover, load balancing across us-east-1, us-east-2, us-west-2
- **auto_prepare**: true - automatically prepares agent after creation/modification
- **idle_session_ttl**: 600 seconds (10 minutes)
- **Action Groups**: Both defined inline with OpenAPI schemas
- **Instructions**: Clear guidance on workflow, session parameters, and action group parameters
- **Dependencies**: Ensures IAM role and Lambda functions exist first

**Validation**: Agent resource defined with both action groups

---

### Parameter Architecture

**Understanding Session Parameters vs Action Group Parameters:**

This architecture uses TWO distinct parameter sources that are combined by the Bedrock Agent runtime:

| Parameter | Source | Passed Via | Received In Lambda | Purpose |
|-----------|--------|------------|-------------------|---------|
| customer_id | Agent Invoker Lambda | sessionAttributes | event['sessionAttributes']['customer_id'] | Customer context across entire session |
| output_type | Action Group Schema | parameters array | event['parameters'][0]['value'] | BDA output type (Standard/Custom) |
| key_pattern | Action Group Schema | parameters array | event['parameters'][1]['value'] | Optional S3 key filter |

**Data Flow:**

1. **Agent Invoker Lambda** calls `invoke_agent()` with:
   ```python
   sessionState = {
       'sessionAttributes': {
           'customer_id': customer_id  # ONLY this is session parameter
       }
   }
   ```

2. **Bedrock Agent Runtime** receives session attributes and stores them for the entire session

3. **Agent decides to invoke GetDocuments** action group

4. **Bedrock Runtime combines:**
   - Session attributes (customer_id from step 1)
   - Schema parameters (output_type, key_pattern from OpenAPI schema)

5. **GetDocuments Lambda receives:**
   ```json
   {
     "sessionAttributes": {"customer_id": "test-123"},
     "parameters": [
       {"name": "output_type", "type": "string", "value": "Standard"},
       {"name": "key_pattern", "type": "string", "value": "*.pdf"}
     ]
   }
   ```


### T-009.4: Create Agent Alias resource

**Purpose**: Create versioned alias for agent invocation

**Actions**:
1. Add to `bedrock.tf`:

```hcl
resource "awscc_bedrock_agent_alias" "kyb_agent_live" {
  agent_alias_name = "live"
  agent_id         = awscc_bedrock_agent.kyb_agent.agent_id
  description      = "Live alias for KYB agent"

  tags = [
    for key, value in local.tags : {
      key   = key
      value = value
    }
  ]

  depends_on = [
    awscc_bedrock_agent.kyb_agent
  ]
}
```

**Pattern Reference**: AWSCC provider alias pattern

**Key Configuration**:
- **Alias Name**: "live" - standard production alias
- **Agent ID**: References parent agent
- **Purpose**: Provides stable endpoint for invocation while allowing agent updates

**Note**: Agent Invoker Lambda will use this alias ID for invocations

**Validation**: Alias resource defined, depends on agent

---

### T-009.5: Update Lambda environment variables with agent references

**Purpose**: Update Agent Invoker Lambda with actual agent IDs

**Actions**:
1. Edit `lambda.tf` - update Agent Invoker function environment block:

```hcl
  environment {
    variables = {
      AGENT_ID          = awscc_bedrock_agent.kyb_agent.agent_id
      AGENT_ALIAS_ID    = awscc_bedrock_agent_alias.kyb_agent_live.agent_alias_id
      PROCESSING_BUCKET = aws_s3_bucket.processing.id
      LOG_LEVEL         = "INFO"
    }
  }
```

**Pattern Reference**: Existing lambda.tf pattern

**Changes**:
- Replace "PLACEHOLDER" values with actual resource references
- Agent Invoker now has real agent ID and alias ID
- These values will be used in T-007 Lambda code implementation

**Validation**: Environment variables reference agent resources

---

### T-009.6: Add Bedrock Agent outputs to outputs.tf

**Purpose**: Expose agent information for verification and downstream use

**Actions**:
1. Add to `outputs.tf`:

```hcl
output "agent_id" {
  description = "ID of the Bedrock KYB Agent"
  value       = awscc_bedrock_agent.kyb_agent.agent_id
}

output "agent_arn" {
  description = "ARN of the Bedrock KYB Agent"
  value       = awscc_bedrock_agent.kyb_agent.agent_arn
}

output "agent_alias_id" {
  description = "ID of the live agent alias"
  value       = awscc_bedrock_agent_alias.kyb_agent_live.agent_alias_id
}

output "agent_alias_arn" {
  description = "ARN of the live agent alias"
  value       = awscc_bedrock_agent_alias.kyb_agent_live.alias_arn
}

output "agent_role_arn" {
  description = "ARN of the Bedrock Agent IAM role"
  value       = aws_iam_role.bedrock_agent_role.arn
}
```

**Pattern Reference**: Standard outputs pattern from outputs.tf

**Outputs Exposed**:
- Agent ID and ARN
- Alias ID and ARN
- Role ARN

**Validation**: 5 new outputs defined

---

### T-009.7: Run validation and formatting

**Purpose**: Ensure Terraform configuration is valid and properly formatted

**Actions**:
1. Navigate to layer directory: `cd data-science/us-east-1/bedrock-agent-kyb`
2. Run `leverage tf validate` - must pass
3. Run `leverage tf format` - format all files
4. Verify no validation errors
5. Review plan for expected resources

**Expected Result**:
- Configuration valid
- All files formatted
- Ready for T-009.8 deployment

**Validation**: `leverage tf validate` returns "Success! The configuration is valid."

---

### T-009.8: Deploy Bedrock Agent infrastructure

**Purpose**: Deploy agent and alias to AWS

**Actions**:
1. Run `leverage tf plan` and review:
   - 1 Bedrock Agent to create
   - 1 Bedrock Agent Alias to create
   - 1 IAM role to create
   - 1 IAM policy to create
   - 1 IAM role policy attachment to create
   - 1 Lambda function to modify (Agent Invoker environment vars)
   - Total: ~6 resources (5 create, 1 modify)

2. Run `leverage tf apply` to deploy

3. Verify outputs:
   - Agent ID present
   - Agent ARN correct
   - Alias ID present
   - Role ARN present

4. Verify agent preparation:
   - Agent status should be "PREPARED" (auto_prepare = true)
   - Both action groups should be visible
   - Agent instructions configured

**Expected Results**:
- Agent created and prepared
- Alias created and active
- IAM role configured with proper permissions
- Agent Invoker Lambda updated with real agent IDs

**Validation**:
- `leverage tf output` shows all 5 agent outputs
- AWS Console shows agent in "PREPARED" state
- Action groups visible in console

---

## Implementation Notes

### AWSCC Provider Choice
- **Preferred**: Comprehensive single-resource configuration
- **Alternative**: AWS provider requires separate resources for agent and action groups
- **Benefit**: Cleaner configuration with all action groups defined inline

### Session Parameters
```python
# In Agent Invoker Lambda (T-007)
response = bedrock_agent_runtime.invoke_agent(
    agentId=agent_id,
    agentAliasId=agent_alias_id,
    sessionId=session_id,
    inputText=input_text,
    sessionState={
        'sessionAttributes': {
            'customer_id': customer_id  # ✅ ONLY session parameter (from API request)
        }
    }
)

```

### Action Group Lambda Events
Action group Lambda functions automatically receive combined data from multiple sources:

**From Session (Agent Invoker Lambda):**
- **event['sessionAttributes']**: Contains ONLY `customer_id`

**From Action Group Schema (OpenAPI definition):**
- **event['parameters']**: Array of parameters defined in schema
  - For GetDocuments: `output_type`
  - For SaveDocument: request body parameters

**From Bedrock Runtime:**
- **event['apiPath']**: API path from schema (`/documents`)
- **event['httpMethod']**: HTTP method from schema (`GET` or `POST`)
- **event['agent']**: Agent metadata (id, name, alias, version)
- **event['actionGroup']**: Action group name (`GetDocuments` or `SaveDocument`)
- **event['messageVersion']**: Protocol version (typically `"1.0"`)

**Example GetDocuments Event Structure:**
```json
{
  "messageVersion": "1.0",
  "sessionAttributes": {
    "customer_id": "test-customer-123"
  },
  "parameters": [
    {"name": "output_type", "type": "string", "value": "Standard"},
    {"name": "key_pattern", "type": "string", "value": "*.pdf"}
  ],
  "actionGroup": "GetDocuments",
  "apiPath": "/documents",
  "httpMethod": "GET",
  "agent": {"id": "...", "name": "kyb_agent", "alias": "live", "version": "1"}
}
```

### Foundation Model Selection

**Using Cross-Region Inference Profiles (Recommended):**
- **Inference Profile**: `us.anthropic.claude-sonnet-4-5-20250929-v1:0`
- **Type**: Cross-region system-defined inference profile
- **Coverage**: Automatic routing across us-east-1, us-east-2, us-west-2
- **Benefits**:
  - Enhanced availability through automatic regional failover
  - Higher aggregate throughput via multi-region load balancing
  - No additional cost vs direct model invocation
  - Built-in redundancy for production workloads
- **Reasoning**: Production-ready architecture with automatic resilience


### Agent Preparation
- **auto_prepare = true**: Agent automatically prepared after creation/modification
- **Preparation**: Compiles agent configuration and makes it ready for invocation
- **Status**: Agent must be in "PREPARED" state for invoke_agent calls

### OpenAPI Schema Requirements
- **Version**: OpenAPI 3.0.0 required
- **operationId**: Required field for newer models (Claude 3.5, Llama)
- **Format**: YAML or JSON supported
- **Storage**: File-based (inline) or S3-based supported

---

## File Summary

**New Files Created** (3 total):
1. `src/schemas/get_documents.yaml` (~40 lines)
2. `src/schemas/save_document.yaml` (~35 lines)
3. This plan file

**Modified Files** (3 total):
1. `bedrock.tf` (+80 lines) - Agent and alias resources
2. `iam.tf` (+60 lines) - Agent role and permissions
3. `lambda.tf` (~5 lines modified) - Agent Invoker env vars
4. `outputs.tf` (+30 lines) - Agent outputs

**Total New Lines**: ~250 lines across all files

---

## Success Criteria

- ✅ OpenAPI schemas created for both action groups
- ✅ Bedrock Agent IAM role configured with proper permissions
- ✅ Agent resource created with 2 action groups
- ✅ Agent alias created for versioning
- ✅ Agent automatically prepared (auto_prepare = true)
- ✅ Agent Invoker Lambda updated with real agent IDs
- ✅ Terraform validation passes
- ✅ All outputs available
- ✅ Code follows minimal implementation principles
- ✅ T-009 marked complete in tasks.md

---

## Next Steps After T-009

After completing T-009, the following tasks can proceed:
- **T-007**: Agent Invoker Lambda Code (depends on T-005, T-009, T-004-API) - T-009 now complete
- **T-008**: GetDocuments Action Group Lambda Code (depends on T-005, T-009) - Ready
- **T-010**: SaveDocument Action Group Lambda Code (depends on T-005, T-009) - Ready
- **T-011**: IAM Permissions Setup (depends on T-002, T-003, T-005, T-009) - Ready

**Recommended Next**: T-008 or T-010 (action group Lambda code) - implements business logic for agent action groups
