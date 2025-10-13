# KYB Agent v2 Implementation Tasks

## Task Overview

This document outlines the implementation tasks for KYB Agent v2, adding the CheckSanctions action group for sanctions and PEP verification. All v1 infrastructure (T-001 through T-012) is already deployed and will be reused.

## Prerequisites from v1

The following v1 components are REQUIRED and already deployed:
- ✅ All infrastructure (S3 buckets, BDA project, EventBridge, API Gateway)
- ✅ All Lambda functions (BDA Invoker, Agent Invoker, GetDocuments, SaveDocument)
- ✅ Bedrock Agent with 2 action groups (GetDocuments, SaveDocument)
- ✅ IAM roles and policies for all existing components

## [ ] T-013: CheckSanctions Lambda Infrastructure
**Requirements**: v2 REQ-SANCTIONS
**Dependencies**: v1 T-005, v1 T-011
**Purpose**: Add CheckSanctions Lambda function infrastructure

### Subtasks:
- [ ] T-013.1: Add `check_sanctions_name` to `locals.tf` naming convention
- [ ] T-013.2: Add archive data source to `lambda.tf` for check-sanctions directory
- [ ] T-013.3: Add `aws_lambda_function.check_sanctions` resource to `lambda.tf`
- [ ] T-013.4: Configure environment variables: `LOG_LEVEL` (demo mode - no external API needed)
- [ ] T-013.5: Add CloudWatch Log Group resource for CheckSanctions Lambda
- [ ] T-013.6: Set runtime to `python3.13`, handler to `lambda_function.lambda_handler`
- [ ] T-013.7: Add Lambda function outputs to `outputs.tf` (name and ARN)

**Example Lambda Resource**:
```hcl
data "archive_file" "check_sanctions" {
  type        = "zip"
  source_dir  = "${path.module}/src/check-sanctions"
  output_path = "${path.module}/check-sanctions.zip"
}

resource "aws_lambda_function" "check_sanctions" {
  filename         = data.archive_file.check_sanctions.output_path
  function_name    = local.check_sanctions_name
  role             = aws_iam_role.check_sanctions_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.check_sanctions.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = merge(local.tags, {
    Name = local.check_sanctions_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.check_sanctions_policy,
    aws_cloudwatch_log_group.check_sanctions_logs
  ]
}

resource "aws_cloudwatch_log_group" "check_sanctions_logs" {
  name              = "/aws/lambda/${local.check_sanctions_name}"
  retention_in_days = 30
  tags              = local.tags
}
```

**Example locals.tf Addition**:
```hcl
check_sanctions_name = "${var.project}-${var.environment}-kyb-agent-check-sanctions"
```

**Note**: No additional variables needed - demo mode uses mocked responses

## [ ] T-014: CheckSanctions Lambda Code
**Requirements**: v2 REQ-SANCTIONS
**Dependencies**: T-013
**Purpose**: Implement Lambda that returns mocked sanctions data (demo mode)

### Subtasks:
- [ ] T-014.1: Create directory `src/check-sanctions/`
- [ ] T-014.2: Create `src/check-sanctions/lambda_function.py` (~80 lines)
- [ ] T-014.3: Parse Bedrock Agent event (messageVersion, actionGroup, apiPath, httpMethod, sessionAttributes, parameters)
- [ ] T-014.4: Extract session parameter `customer_id` for logging
- [ ] T-014.5: Parse query parameters: `name`, `surname`, `document_id`
- [ ] T-014.6: Validate input (require name+surname OR document_id)
- [ ] T-014.7: Generate mocked sanctions data using isolated function
- [ ] T-014.8: Return random `num_sanctions` (0-2) and `pep_score` (0.0-1.0)
- [ ] T-014.9: Return Bedrock Agent response format with status code and body

**Example Lambda Code Structure**:
```python
import json
import random

def lambda_handler(event, _context):
    """Bedrock Agent action group handler for sanctions checking"""
    message_version = event.get("messageVersion", "1.0")
    action_group = event["actionGroup"]
    api_path = event["apiPath"]
    http_method = event["httpMethod"]

    session_attrs = event.get("sessionAttributes", {})
    customer_id = session_attrs.get("customer_id")

    parameters = {}
    if "parameters" in event and isinstance(event["parameters"], list):
        for param in event["parameters"]:
            if isinstance(param, dict) and "name" in param:
                parameters[param["name"]] = param.get("value", "")

    name = parameters.get("name")
    surname = parameters.get("surname")
    document_id = parameters.get("document_id")

    if not document_id and not (name and surname):
        return create_response(
            message_version, action_group, api_path, http_method,
            400, {"error": "Either document_id or name+surname required"}
        )

    sanctions_data = check_sanctions(name, surname, document_id)

    return create_response(
        message_version, action_group, api_path, http_method,
        200, sanctions_data
    )

def check_sanctions(name, surname, document_id):
    """Check sanctions status - DEMO: returns mocked random data"""
    if document_id:
        query_type = "document_id"
        query_value = document_id
    else:
        query_type = "name"
        query_value = f"{name} {surname}"

    return get_mocked_sanctions_data(query_type, query_value)

def get_mocked_sanctions_data(query_type, query_value):
    """Generate mocked sanctions data for demo purposes

    To replace with real API: modify this function to call external service
    Example:
        response = requests.post(API_ENDPOINT, json={...})
        return response.json()
    """
    random.seed(hash(query_value) % 10000)

    scenarios = [
        {"num_sanctions": 0, "pep_score": 0.1},
        {"num_sanctions": 0, "pep_score": 0.3},
        {"num_sanctions": 0, "pep_score": 0.5},
        {"num_sanctions": 0, "pep_score": 0.8},
        {"num_sanctions": 1, "pep_score": 0.2},
        {"num_sanctions": 2, "pep_score": 0.9},
    ]

    result = random.choice(scenarios)

    return {
        "num_sanctions": result["num_sanctions"],
        "pep_score": result["pep_score"],
        "query_type": query_type,
        "query_value": query_value
    }

def create_response(message_version, action_group, api_path, http_method, status_code, body):
    """Create Bedrock Agent response format"""
    return {
        "messageVersion": message_version,
        "response": {
            "actionGroup": action_group,
            "apiPath": api_path,
            "httpMethod": http_method,
            "httpStatusCode": status_code,
            "responseBody": {
                "application/json": {"body": json.dumps(body, default=str)}
            }
        }
    }
```

## [ ] T-015: CheckSanctions Action Group Registration
**Requirements**: v2 REQ-SANCTIONS
**Dependencies**: T-013, T-014, v1 T-009
**Purpose**: Register CheckSanctions as third action group in Bedrock Agent

### Subtasks:
- [ ] T-015.1: Create `src/schemas/check_sanctions.yaml` OpenAPI schema
- [ ] T-015.2: Add `aws_bedrockagent_agent_action_group.check_sanctions` resource to `bedrock.tf`
- [ ] T-015.3: Configure action group with Lambda executor pointing to `aws_lambda_function.check_sanctions.arn`
- [ ] T-015.4: Add Lambda permission for Bedrock invocation to `iam.tf`
- [ ] T-015.5: Update Bedrock Agent instructions in `bedrock.tf` with KYB compliance logic
- [ ] T-015.6: Add CheckSanctions action group to agent alias dependencies

**Example OpenAPI Schema** (`src/schemas/check_sanctions.yaml`):
```yaml
openapi: 3.0.0
info:
  title: CheckSanctions Action
  version: 1.0.0
  description: Returns mocked sanctions and PEP verification data (demo mode)
paths:
  /sanctions:
    get:
      operationId: checkSanctions
      description: Check if a person has sanctions or is politically exposed
      parameters:
        - name: name
          in: query
          required: false
          description: Person's first name (required if document_id not provided)
          schema:
            type: string
        - name: surname
          in: query
          required: false
          description: Person's last name (required if document_id not provided)
          schema:
            type: string
        - name: document_id
          in: query
          required: false
          description: Person's document ID (passport, national ID, tax ID)
          schema:
            type: string
      responses:
        "200":
          description: Sanctions check completed successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  num_sanctions:
                    type: integer
                    description: Number of active sanctions
                  pep_score:
                    type: number
                    description: Political exposure score (0.0-1.0)
                  query_type:
                    type: string
                    description: Type of query performed (name or document_id)
                  query_value:
                    type: string
                    description: Value used for the query
```

**Example Action Group Resource** (add to `bedrock.tf`):
```hcl
resource "aws_bedrockagent_agent_action_group" "check_sanctions" {
  action_group_name          = "CheckSanctions"
  agent_id                   = awscc_bedrock_agent.kyb_agent.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  prepare_agent              = false
  description                = "Returns mocked sanctions and PEP verification data"

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
```

**Example Lambda Permission** (add to `iam.tf`):
```hcl
resource "aws_lambda_permission" "allow_bedrock_check_sanctions" {
  statement_id  = "AllowExecutionFromBedrock"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_sanctions.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"
}
```

**Example Agent Instructions Update** (update `bedrock.tf` awscc_bedrock_agent resource):
```hcl
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
```

**Update Agent Alias Dependencies** (in `bedrock.tf`):
```hcl
resource "awscc_bedrock_agent_alias" "kyb_agent_live" {
  # ... existing configuration ...

  depends_on = [
    awscc_bedrock_agent.kyb_agent,
    aws_bedrockagent_agent_action_group.get_documents,
    aws_bedrockagent_agent_action_group.save_document,
    aws_bedrockagent_agent_action_group.check_sanctions  # NEW
  ]
}
```

## [ ] T-016: CheckSanctions IAM Permissions
**Requirements**: v2 REQ-SANCTIONS
**Dependencies**: T-013, v1 T-011
**Purpose**: Create IAM role and policies for CheckSanctions Lambda

### Subtasks:
- [ ] T-016.1: Add CheckSanctions policy document to `iam.tf` (CloudWatch Logs only - no external API)
- [ ] T-016.2: Create IAM policy resource from policy document
- [ ] T-016.3: Create IAM role with Lambda assume role policy
- [ ] T-016.4: Attach policy to role
- [ ] T-016.5: Update CheckSanctions Lambda to use new role
- [ ] T-016.6: Update Bedrock Agent policy to include CheckSanctions Lambda invocation
- [ ] T-016.7: Add CheckSanctions role ARN to `outputs.tf`

**Example IAM Policy Document** (add to `iam.tf`):
```hcl
data "aws_iam_policy_document" "check_sanctions_policy" {
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.check_sanctions_name}:*"]
  }
}

resource "aws_iam_role" "check_sanctions_role" {
  name               = "${local.check_sanctions_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_policy" "check_sanctions_policy" {
  name   = "${local.check_sanctions_name}-policy"
  policy = data.aws_iam_policy_document.check_sanctions_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "check_sanctions_policy" {
  role       = aws_iam_role.check_sanctions_role.name
  policy_arn = aws_iam_policy.check_sanctions_policy.arn
}
```

**Update Bedrock Agent Policy** (update existing policy in `iam.tf`):
```hcl
data "aws_iam_policy_document" "bedrock_agent_permissions" {
  # ... existing statements ...

  statement {
    sid     = "ActionGroupLambdaAccess"
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.get_documents.arn,
      aws_lambda_function.save_document.arn,
      aws_lambda_function.check_sanctions.arn  # NEW
    ]
  }
}
```

## [ ] T-017: Deployment and Verification
**Requirements**: v2 REQ-SANCTIONS
**Dependencies**: T-013, T-014, T-015, T-016
**Purpose**: Deploy and verify CheckSanctions integration

### Subtasks:
- [ ] T-017.1: Run `leverage tf validate` to check configuration
- [ ] T-017.2: Run `leverage tf plan` and review changes
- [ ] T-017.3: Run `leverage tf apply` to deploy CheckSanctions resources
- [ ] T-017.4: Create test event for CheckSanctions Lambda with name+surname
- [ ] T-017.5: Create test event for CheckSanctions Lambda with document_id
- [ ] T-017.6: Verify CheckSanctions Lambda returns mocked sanctions data
- [ ] T-017.8: Invoke Bedrock Agent via API Gateway and verify sanctions checking in flow
- [ ] T-017.9: Verify Agent makes APPROVED/REJECTED/REVIEW_REQUIRED decisions based on sanctions data
- [ ] T-017.10: Verify SaveDocument includes sanctions data in verdict

**Test Event Example** (`testing/events/check-sanctions-name-test.json`):
```json
{
  "messageVersion": "1.0",
  "sessionAttributes": {
    "customer_id": "test-customer-123"
  },
  "actionGroup": "CheckSanctions",
  "apiPath": "/sanctions",
  "httpMethod": "GET",
  "parameters": [
    {
      "name": "name",
      "value": "John"
    },
    {
      "name": "surname",
      "value": "Doe"
    }
  ]
}
```

**Test Event Example** (`testing/events/check-sanctions-id-test.json`):
```json
{
  "messageVersion": "1.0",
  "sessionAttributes": {
    "customer_id": "test-customer-123"
  },
  "actionGroup": "CheckSanctions",
  "apiPath": "/sanctions",
  "httpMethod": "GET",
  "parameters": [
    {
      "name": "document_id",
      "value": "12345678A"
    }
  ]
}
```

**Verification Commands**:
```bash
# Test CheckSanctions Lambda directly
leverage aws lambda invoke \
  --function-name bb-data-science-kyb-agent-check-sanctions \
  --cli-binary-format raw-in-base64-out \
  --payload file://testing/events/check-sanctions-name-test.json \
  /tmp/check-sanctions-response.json

# Check CloudWatch logs
leverage aws logs tail /aws/lambda/bb-data-science-kyb-agent-check-sanctions --since 5m --format short

# Test end-to-end via API Gateway
awscurl --service execute-api -X POST \
  -d '{"customer_id":"test-customer-123"}' \
  -H "Content-Type: application/json" \
  "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/v1/invoke-agent"
```

## Implementation Order

1. **Phase 1**: Lambda Infrastructure (T-013)
2. **Phase 2**: Lambda Code (T-014)
3. **Phase 3**: Action Group Registration (T-015)
4. **Phase 4**: IAM Permissions (T-016)
5. **Phase 5**: Deployment and Verification (T-017)

## Success Criteria

- [ ] CheckSanctions Lambda deployed (demo mode with mocked data)
- [ ] CheckSanctions Lambda returns valid response with num_sanctions and pep_score
- [ ] CheckSanctions action group registered in Bedrock Agent
- [ ] Bedrock Agent can invoke CheckSanctions action group
- [ ] Agent instructions include KYB compliance logic
- [ ] Agent makes APPROVED/REJECTED/REVIEW_REQUIRED decisions
- [ ] SaveDocument includes representatives sanctions data in verdict
- [ ] End-to-end flow tested via API Gateway

## Notes

- All v1 infrastructure remains unchanged (no modifications to existing resources)
- CheckSanctions Lambda is isolated (no S3 or external API access - demo mode only)
- Demo mode uses mocked random sanctions data with isolated functions for easy API integration later
- Bedrock Agent now has 3 action groups: GetDocuments, CheckSanctions, SaveDocument
- Agent instructions updated to include sanctions verification workflow
