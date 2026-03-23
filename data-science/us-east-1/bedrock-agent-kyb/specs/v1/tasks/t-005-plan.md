# T-005: Lambda Functions Implementation - Detailed Plan

## Overview
Implement Lambda infrastructure for the KYB Agent pipeline with 4 functions following minimal implementation principles (DRY, KISS, YAGNI).

## Execution Strategy
Execute subtasks **sequentially** in the order listed below. Each subtask must complete and validate before moving to the next.

---

## Subtask Breakdown

### T-005.1: Create `lambda.tf` file with archive data sources

**Purpose**: Set up Lambda packaging infrastructure

**Actions**:
1. Create `lambda.tf` file
2. Add 4 `archive_file` data sources:
   - `bda_invoker` - packages `src/bda-invoker/`
   - `agent_invoker` - packages `src/agent-invoker/`
   - `get_documents` - packages `src/get-documents/`
   - `save_document` - packages `src/save-document/`

**Pattern Reference**: `/data-science/us-east-1/bedrock-kyb-bda/lambda.tf`

**Validation**: File created, no syntax errors

---

### T-005.2: Create Lambda source directories with minimal handlers

**Purpose**: Create placeholder Python handlers for all 4 functions

**Actions**:
1. Create directory structure:
   ```
   src/
   ├── bda-invoker/
   │   └── lambda_function.py
   ├── agent-invoker/
   │   └── lambda_function.py
   ├── get-documents/
   │   └── lambda_function.py
   └── save-document/
       └── lambda_function.py
   ```

2. Each handler contains minimal stub:
   ```python
   import json
   import logging

   logger = logging.getLogger()
   logger.setLevel(logging.INFO)

   def lambda_handler(event, context):
       """Minimal placeholder - business logic in T-006, T-007, T-008, T-010"""
       logger.info(f"Event: {json.dumps(event)}")
       return {"statusCode": 200, "body": json.dumps({"status": "not_implemented"})}
   ```

**Pattern Reference**: Minimal structure from bedrock-kyb-bda

**Validation**: All 4 files created with valid Python syntax

---

### T-005.3: Add Lambda function resources to `lambda.tf`

**Purpose**: Define all 4 Lambda functions with proper configuration

**Actions**:
1. Add BDA Invoker Lambda function resource:
   - Runtime: `python3.13`
   - Handler: `lambda_function.lambda_handler`
   - Role: `aws_iam_role.bda_invoker_role.arn` (created in T-005.5)
   - Timeout: `var.lambda_timeout` (default 60s)
   - Memory: `var.lambda_memory_size` (default 512MB)
   - Environment variables:
     - `BDA_PROJECT_ARN`
     - `INPUT_BUCKET`
     - `PROCESSING_BUCKET`
     - `LOG_LEVEL`
   - Source code hash for change detection
   - Tags with Name

2. Add Agent Invoker Lambda function resource:
   - Same configuration pattern
   - Environment variables:
     - `AGENT_ID` (placeholder, will reference from T-009)
     - `AGENT_ALIAS_ID` (placeholder)
     - `PROCESSING_BUCKET`
     - `LOG_LEVEL`

3. Add GetDocuments Lambda function resource:
   - Same configuration pattern
   - Environment variables:
     - `PROCESSING_BUCKET`
     - `LOG_LEVEL`

4. Add SaveDocument Lambda function resource:
   - Same configuration pattern
   - Environment variables:
     - `OUTPUT_BUCKET`
     - `LOG_LEVEL`

**Pattern Reference**: `/data-science/us-east-1/bedrock-kyb-bda/lambda.tf`

**Key Configuration**:
- Use `source_code_hash = data.archive_file.*.output_base64sha256` for updates
- Use `depends_on` for IAM role policy attachments and log groups
- Use `local.*_name` for function names from locals.tf

**Validation**: Terraform syntax valid, all resources defined

---

### T-005.4: Add CloudWatch Log Groups to `lambda.tf`

**Purpose**: Create explicit log groups with retention policy

**Actions**:
1. Add 4 `aws_cloudwatch_log_group` resources:
   - Name pattern: `/aws/lambda/${local.*_name}`
   - Retention: 30 days
   - Tags: `local.tags`

2. Add to Lambda `depends_on`:
   ```hcl
   depends_on = [
     aws_cloudwatch_log_group.function_logs,
     aws_iam_role_policy_attachment.function_policy
   ]
   ```

**Pattern Reference**: `/data-science/us-east-1/bedrock-kyb-bda/lambda.tf`

**Validation**: Log groups defined for all 4 functions

---

### T-005.5: Create `iam.tf` with Lambda execution roles

**Purpose**: Define IAM roles and policies for Lambda execution

**Actions**:
1. Create `iam.tf` file

2. For **each of the 4 Lambda functions**, create:

   **A. Assume Role Policy Document**:
   ```hcl
   data "aws_iam_policy_document" "function_assume_role" {
     statement {
       effect = "Allow"
       principals {
         type        = "Service"
         identifiers = ["lambda.amazonaws.com"]
       }
       actions = ["sts:AssumeRole"]
     }
   }
   ```

   **B. Permissions Policy Document** (function-specific):
   - **BDA Invoker**: S3 GetObject (input bucket), BDA InvokeDataAutomation, CloudWatch Logs
   - **Agent Invoker**: Bedrock InvokeAgent, S3 ListObjectsV2/GetObject (processing bucket), CloudWatch Logs
   - **GetDocuments**: S3 ListObjectsV2/GetObject (processing bucket), CloudWatch Logs
   - **SaveDocument**: S3 PutObject (output bucket), CloudWatch Logs

   **C. IAM Role Resource**:
   ```hcl
   resource "aws_iam_role" "function_role" {
     name               = "${local.function_name}-role"
     assume_role_policy = data.aws_iam_policy_document.function_assume_role.json
     tags               = local.tags
   }
   ```

   **D. IAM Policy Resource**:
   ```hcl
   resource "aws_iam_policy" "function_policy" {
     name   = "${local.function_name}-policy"
     policy = data.aws_iam_policy_document.function_policy.json
     tags   = local.tags
   }
   ```

   **E. Policy Attachment**:
   ```hcl
   resource "aws_iam_role_policy_attachment" "function_policy" {
     role       = aws_iam_role.function_role.name
     policy_arn = aws_iam_policy.function_policy.arn
   }
   ```

**Pattern Reference**: `/data-science/us-east-1/bedrock-kyb-bda/iam.tf` (data source pattern)

**IAM Permissions Breakdown**:

**BDA Invoker Permissions**:
- CloudWatch Logs: `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
- S3 Input Bucket: `s3:GetObject`
- BDA: `bedrock:InvokeDataAutomationAsync`

**Agent Invoker Permissions**:
- CloudWatch Logs: Standard logging permissions
- Bedrock: `bedrock:InvokeAgent`
- S3 Processing Bucket: `s3:ListBucket`, `s3:GetObject` (for validation)

**GetDocuments Permissions**:
- CloudWatch Logs: Standard logging permissions
- S3 Processing Bucket: `s3:ListBucket`, `s3:GetObject`

**SaveDocument Permissions**:
- CloudWatch Logs: Standard logging permissions
- S3 Output Bucket: `s3:PutObject`

**Validation**: All IAM resources defined, policies follow least privilege

---

### T-005.6: Add Lambda permissions for service invocation

**Purpose**: Allow AWS services to invoke Lambda functions

**Actions**:
1. Add to `lambda.tf`:

   **BDA Invoker Permission** (EventBridge invocation):
   ```hcl
   resource "aws_lambda_permission" "allow_eventbridge_bda_invoker" {
     statement_id  = "AllowExecutionFromEventBridge"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.bda_invoker.function_name
     principal     = "events.amazonaws.com"
     source_arn    = aws_cloudwatch_event_rule.input_bucket_trigger.arn
   }
   ```
   Note: EventBridge rule will be created in T-004

   **Agent Invoker Permission** (API Gateway invocation):
   ```hcl
   resource "aws_lambda_permission" "allow_apigateway_agent_invoker" {
     statement_id  = "AllowExecutionFromAPIGateway"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.agent_invoker.function_name
     principal     = "apigateway.amazonaws.com"
     source_arn    = "${aws_api_gateway_rest_api.kyb_agent.execution_arn}/*/*/*"
   }
   ```
   Note: API Gateway will be created in T-004-API

   **GetDocuments & SaveDocument Permissions** (Bedrock Agent invocation):
   ```hcl
   resource "aws_lambda_permission" "allow_bedrock_get_documents" {
     statement_id  = "AllowExecutionFromBedrock"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.get_documents.function_name
     principal     = "bedrock.amazonaws.com"
     source_arn    = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"
   }

   resource "aws_lambda_permission" "allow_bedrock_save_document" {
     statement_id  = "AllowExecutionFromBedrock"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.save_document.function_name
     principal     = "bedrock.amazonaws.com"
     source_arn    = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"
   }
   ```

**Pattern Reference**: `/data-science/us-east-1/bedrock-kyb-bda/lambda.tf`

**Validation**: All 4 Lambda permissions defined

---

### T-005.7: Add Lambda variables to `variables.tf`

**Purpose**: Define configurable Lambda parameters

**Actions**:
1. Add to `variables.tf`:

```hcl
variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds"
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240 MB"
  }
}
```

**Pattern Reference**: Standard Lambda variable pattern

**Validation**: Variables defined with validation rules

---

### T-005.8: Add Lambda outputs to `outputs.tf`

**Purpose**: Expose Lambda function information for downstream resources

**Actions**:
1. Add to `outputs.tf`:

```hcl
# BDA Invoker outputs
output "bda_invoker_function_name" {
  description = "Name of the BDA Invoker Lambda function"
  value       = aws_lambda_function.bda_invoker.function_name
}

output "bda_invoker_function_arn" {
  description = "ARN of the BDA Invoker Lambda function"
  value       = aws_lambda_function.bda_invoker.arn
}

# Agent Invoker outputs
output "agent_invoker_function_name" {
  description = "Name of the Agent Invoker Lambda function"
  value       = aws_lambda_function.agent_invoker.function_name
}

output "agent_invoker_function_arn" {
  description = "ARN of the Agent Invoker Lambda function"
  value       = aws_lambda_function.agent_invoker.arn
}

# GetDocuments outputs
output "get_documents_function_name" {
  description = "Name of the GetDocuments Lambda function"
  value       = aws_lambda_function.get_documents.function_name
}

output "get_documents_function_arn" {
  description = "ARN of the GetDocuments Lambda function"
  value       = aws_lambda_function.get_documents.arn
}

# SaveDocument outputs
output "save_document_function_name" {
  description = "Name of the SaveDocument Lambda function"
  value       = aws_lambda_function.save_document.function_name
}

output "save_document_function_arn" {
  description = "ARN of the SaveDocument Lambda function"
  value       = aws_lambda_function.save_document.arn
}
```

**Validation**: 8 outputs defined (name + ARN for each function)

---

### T-005.9: Run validation and formatting

**Purpose**: Ensure Terraform configuration is valid and properly formatted

**Actions**:
1. Navigate to layer directory: `cd data-science/us-east-1/bedrock-agent-kyb`
2. Run `leverage tf init` (if needed)
3. Run `leverage tf validate` - must pass
4. Run `leverage tf format` - format all files
5. Verify no validation errors

**Expected Result**:
- Configuration valid
- All files formatted
- Ready for T-005.10 deployment

**Validation**: `leverage tf validate` returns "Success! The configuration is valid."

---

### T-005.10: Deploy Lambda infrastructure

**Purpose**: Deploy all Lambda functions to AWS

**Actions**:
1. Run `leverage tf plan` and review:
   - 4 Lambda functions to create
   - 4 CloudWatch log groups to create
   - 4 IAM roles to create
   - 4 IAM policies to create
   - 4 IAM role policy attachments to create
   - 4 Lambda permissions to create
   - Total: ~24 resources to add

2. Run `leverage tf apply` to deploy

3. Verify outputs:
   - All Lambda function ARNs present
   - All function names correct

**Expected Results**:
- All resources created successfully
- Lambda functions visible in AWS Console
- CloudWatch log groups created
- IAM roles and policies active

**Validation**:
- `leverage tf output` shows all 8 Lambda outputs
- AWS Console shows 4 Lambda functions deployed

---

## Implementation Notes

### Minimal Implementation Principles
- **No error handling** beyond basic AWS SDK defaults
- **No logging** beyond minimal operational needs (standard Python logging)
- **No Lambda layer** - using only boto3 and standard library
- **Minimal comments** - code should be self-documenting
- **No testing frameworks** - validation through deployment
- **No defensive programming** patterns

### Python Handler Standards
- Use standard Python `logging` module (not structlog)
- Import only what's needed: `json`, `logging`, `boto3`
- Single `lambda_handler` function entry point
- Return standard API Gateway/Lambda response format
- Business logic implementation deferred to T-006, T-007, T-008, T-010

### Resource Naming
All resource names use locals from `locals.tf`:
- `local.bda_invoker_name` → `bb-data-science-kyb-agent-bda-invoker`
- `local.agent_invoker_name` → `bb-data-science-kyb-agent-invoker`
- `local.get_documents_name` → `bb-data-science-kyb-agent-get-docs`
- `local.save_document_name` → `bb-data-science-kyb-agent-save-doc`

### Runtime Selection: Python 3.13
- Latest Python runtime for Lambda
- Best for new features and performance
- Used by `/data-science/us-east-1/bedrock-agent/` reference implementation
- Supports all required boto3 features

### Dependencies on Future Tasks
- **T-004**: EventBridge rule ARN for BDA Invoker permission (referenced but not blocking)
- **T-004-API**: API Gateway ARN for Agent Invoker permission (referenced but not blocking)
- **T-009**: Agent ID/Alias ID for Agent Invoker environment variables (can use placeholders)

**Note**: Lambda permissions reference resources that don't exist yet. These won't cause validation errors but will show as planned resources. They'll be updated when T-004 and T-004-API are completed.

---

## File Summary

**New Files Created** (9 total):
1. `lambda.tf` (~220 lines)
2. `iam.tf` (~200 lines)
3. `src/bda-invoker/lambda_function.py` (~10 lines)
4. `src/agent-invoker/lambda_function.py` (~10 lines)
5. `src/get-documents/lambda_function.py` (~10 lines)
6. `src/save-document/lambda_function.py` (~10 lines)
7. This plan file

**Modified Files** (2 total):
1. `variables.tf` (+24 lines)
2. `outputs.tf` (+48 lines)

**Total New Lines**: ~540 lines across all files

---

## Success Criteria

- ✅ All 4 Lambda functions created in AWS
- ✅ All 4 CloudWatch log groups exist with 30-day retention
- ✅ All 4 IAM roles created with proper policies
- ✅ Terraform validation passes
- ✅ All outputs available
- ✅ Code follows minimal implementation principles
- ✅ T-005 marked complete in tasks.md

---

## Next Steps After T-005

After completing T-005, the following tasks can proceed:
- **T-004**: EventBridge Rules (depends on T-005)
- **T-004-API**: API Gateway Setup (depends on T-005)
- **T-006**: BDA Invoker Lambda Code (depends on T-005)
- **T-007**: Agent Invoker Lambda Code (depends on T-005)
- **T-008**: GetDocuments Action Group (depends on T-005)
