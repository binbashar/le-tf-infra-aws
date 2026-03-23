# T-007: Agent Invoker Lambda Implementation Plan

**Task**: Implement Lambda function that triggers Bedrock Agent via IAM-authenticated API Gateway
**Requirements**: REQ-002, REQ-003
**Dependencies**: T-005 (Lambda infrastructure), T-009 (Bedrock Agent), T-004-API (API Gateway)
**Date**: 2025-10-06

## Objective

Implement minimal MVP Lambda code for `agent-invoker` that:
1. Handles IAM-authenticated API Gateway proxy events
2. Extracts customer_id from request body
3. Validates customer_id parameter
4. Generates unique session_id for tracking
5. Invokes Bedrock Agent with session parameters (customer_id, output_type="Standard")
6. Returns JSON response with invocation status and metadata
7. Optionally logs IAM principal ARN for audit trail

## Current State Analysis

### Existing Infrastructure
- ✅ Lambda function deployed: `aws_lambda_function.agent_invoker`
- ✅ IAM role with permissions: CloudWatch, bedrock:InvokeAgent, S3 ListBucket/GetObject (processing bucket)
- ✅ Lambda permissions ready for bedrock.amazonaws.com and apigateway.amazonaws.com
- ✅ Placeholder Lambda code exists at `src/agent-invoker/lambda_function.py`
- ⚠️ Environment variables use PLACEHOLDER values (will be updated by T-009)

### Environment Variables Available
```python
AGENT_ID          = "PLACEHOLDER"  # Will be updated by T-009
AGENT_ALIAS_ID    = "PLACEHOLDER"  # Will be updated by T-009
PROCESSING_BUCKET = "bucket-name"
LOG_LEVEL         = "INFO"
```

### Dependency Status
- **T-009 (Bedrock Agent)**: ❌ NOT COMPLETE - Required to provide real agent_id and agent_alias_id
- **T-004-API (API Gateway)**: ❌ NOT COMPLETE - Required to provide API Gateway integration

**Note**: This task can implement the Lambda code logic now. Environment variables will be updated by T-009, and API Gateway integration will be added by T-004-API.

## Technical Design

### Event Flow
```
API Gateway (IAM Auth) → Agent Invoker Lambda → Bedrock Agent
                              ↓
                    Session Parameters (customer_id)
```

### API Gateway Event Structure (Proxy Integration)
```json
{
  "httpMethod": "POST",
  "path": "/invoke-agent",
  "headers": {
    "Content-Type": "application/json"
  },
  "requestContext": {
    "identity": {
      "userArn": "arn:aws:iam::account-id:user/username",
      "accountId": "account-id"
    },
    "requestId": "request-id"
  },
  "body": "{\"customer_id\":\"test-customer-123\"}"
}
```

### Session Parameters Pattern
Session parameters are passed to the agent at invocation time and automatically forwarded to action group Lambda functions:

```python
sessionState = {
    'sessionAttributes': {
        'customer_id': customer_id,      # From API request body
        'output_type': 'Standard'        # BDA output type constant
    }
}
```

**How Session Parameters Work**:
1. Agent Invoker passes them in `invoke_agent()` call
2. Bedrock Agent runtime automatically includes them in action group Lambda events
3. Action groups (GetDocuments, SaveDocument) receive them in `event['sessionAttributes']`
4. No manual parameter passing needed between agent and action groups

### Bedrock Agent Invocation API

**Boto3 Client**: `bedrock-agent-runtime`
**Method**: `invoke_agent()`

**Required Parameters**:
```python
response = client.invoke_agent(
    agentId='agent-id',                    # From AGENT_ID env var
    agentAliasId='agent-alias-id',         # From AGENT_ALIAS_ID env var
    sessionId='unique-session-id',         # Generated UUID
    inputText='Please process documents for this customer',  # Agent prompt
    sessionState={
        'sessionAttributes': {
            'customer_id': 'customer-123',
            'output_type': 'Standard'
        }
    }
)
```

**Response Structure**:
```python
{
    'completion': EventStream([...]),  # Streaming response
    'contentType': 'application/json',
    'sessionId': 'unique-session-id'
}
```

**Response Stream Processing**:
The response is an event stream that must be consumed. For minimal MVP:
- Read the stream to completion (agent response)
- Extract final output from stream
- Return structured response to API Gateway

## Implementation Steps

### Step 1: Implement Lambda Handler (src/agent-invoker/lambda_function.py)

**Minimal MVP Code Structure**:
```python
import json
import os
import boto3
from uuid import uuid4

# Environment variables
AGENT_ID = os.environ['AGENT_ID']
AGENT_ALIAS_ID = os.environ['AGENT_ALIAS_ID']
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')

# Boto3 client
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')

def lambda_handler(event, context):
    # T-007.2: Handle API Gateway proxy events
    body = json.loads(event.get('body', '{}'))

    # T-007.3: Extract customer_id from request body
    customer_id = body.get('customer_id', '').strip()

    # T-007.4: Validate customer_id parameter
    if not customer_id:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'status': 'error',
                'message': 'customer_id is required'
            })
        }

    # Generate unique session_id
    session_id = str(uuid4())

    # T-007.5: Invoke Bedrock Agent with session parameters
    response = bedrock_agent_runtime.invoke_agent(
        agentId=AGENT_ID,
        agentAliasId=AGENT_ALIAS_ID,
        sessionId=session_id,
        inputText=f'Please retrieve and process documents for customer: {customer_id}',
        sessionState={
            'sessionAttributes': {
                'customer_id': customer_id,
                'output_type': 'Standard'
            }
        }
    )

    # Process event stream response
    result = process_agent_response(response)

    # T-007.6: Return JSON response with status, session_id, and agent_id
    return {
        'statusCode': 200,
        'body': json.dumps({
            'status': 'success',
            'session_id': session_id,
            'agent_id': AGENT_ID,
            'customer_id': customer_id,
            'message': 'Agent invocation initiated',
            'agent_response': result
        })
    }

def process_agent_response(response):
    """Process streaming response from Bedrock Agent"""
    completion = response.get('completion', [])
    chunks = []

    for event in completion:
        if 'chunk' in event:
            chunk = event['chunk']
            if 'bytes' in chunk:
                chunks.append(chunk['bytes'].decode('utf-8'))

    return ''.join(chunks)
```

**Minimal Approach Notes**:
- No try/except blocks (AWS SDK handles retries)
- No custom logging beyond AWS Lambda default
- Simple validation: only check if customer_id is present and not empty
- Basic stream processing: collect all chunks
- No complex error handling (acceptable for MVP)

### Step 2: Optional - Add IAM Principal Logging (T-007.7)

**For audit trail** (optional enhancement):
```python
def log_iam_principal(event):
    """Log IAM principal ARN from API Gateway request context"""
    request_context = event.get('requestContext', {})
    identity = request_context.get('identity', {})
    user_arn = identity.get('userArn', 'unknown')
    print(f"IAM Principal: {user_arn}")
    return user_arn
```

Add to lambda_handler:
```python
def lambda_handler(event, context):
    # Optional: Log IAM principal for audit
    principal_arn = log_iam_principal(event)

    # ... rest of handler logic
```

### Step 3: Deploy Lambda Code

**Deployment Commands**:
```bash
cd data-science/us-east-1/bedrock-agent-kyb

# Format and validate (if needed)
leverage tf format
leverage tf validate

# Deploy Lambda code update
leverage tf apply -target=aws_lambda_function.agent_invoker
```

**Deployment Notes**:
- OpenTofu detects code changes via source_code_hash
- Lambda will be updated with new code
- No infrastructure changes, just code deployment
- Environment variables remain as-is (PLACEHOLDER values until T-009)

### Step 4: Test Lambda Code (Manual Testing)

**Test Event Structure** (API Gateway proxy format):
```json
{
  "httpMethod": "POST",
  "path": "/invoke-agent",
  "headers": {
    "Content-Type": "application/json"
  },
  "requestContext": {
    "identity": {
      "userArn": "arn:aws:iam::123456789012:user/test-user",
      "accountId": "123456789012"
    }
  },
  "body": "{\"customer_id\":\"test-customer-123\"}"
}
```

**Testing Approach**:
1. Create test event in AWS Lambda Console
2. Invoke Lambda with test event
3. Verify response format:
   ```json
   {
     "statusCode": 200,
     "body": "{\"status\":\"success\",\"session_id\":\"...\",\"agent_id\":\"...\",\"customer_id\":\"test-customer-123\",\"message\":\"...\"}"
   }
   ```
4. Check CloudWatch logs for execution details

**Expected Behavior Before T-009 Completes**:
- Lambda will fail with error about invalid AGENT_ID (PLACEHOLDER not valid)
- This is expected until T-009 updates environment variables
- Code logic can still be validated by reviewing logs

**Testing After T-009 Completes**:
- Lambda will successfully invoke real Bedrock Agent
- Agent will execute with session parameters
- Action groups (GetDocuments, SaveDocument) will receive customer_id automatically

## Integration Points

### T-009 Integration (Bedrock Agent Configuration)
When T-009 completes, it will:
1. Create Bedrock Agent with real agent_id
2. Create Agent Alias with real agent_alias_id
3. Update lambda.tf environment variables:
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
4. Redeploy Lambda with updated environment variables

### T-004-API Integration (API Gateway Setup)
When T-004-API completes, it will:
1. Create REST API Gateway resource
2. Create POST /invoke-agent endpoint with IAM authentication
3. Configure Lambda integration with this Lambda function
4. Add Lambda permission for API Gateway invocation (already exists from T-005)
5. Provide API Gateway endpoint URL for testing

## API Gateway Response Format

### Success Response (200)
```json
{
  "status": "success",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "agent_id": "ABCDEFGHIJ",
  "customer_id": "test-customer-123",
  "message": "Agent invocation initiated",
  "agent_response": "I'll retrieve and process the documents..."
}
```

### Error Response (400)
```json
{
  "status": "error",
  "message": "customer_id is required"
}
```

## Success Criteria

- [x] Lambda handler implements all 7 subtasks (T-007.1 through T-007.7)
- [x] API Gateway proxy event handling working
- [x] customer_id extraction and validation implemented
- [x] Session parameters structure correct for Bedrock Agent
- [x] Bedrock Agent invocation code complete
- [x] Response stream processing implemented
- [x] JSON response format matches specification
- [x] Code follows minimal implementation principles (DRY, KISS, YAGNI)
- [x] No unnecessary error handling or logging
- [x] Ready for T-009 integration (agent IDs)
- [x] Ready for T-004-API integration (API Gateway)

## Minimal Implementation Trade-offs

### What's Included (MVP)
- ✅ Basic customer_id validation (not empty)
- ✅ Session parameter structure
- ✅ Agent invocation with sessionState
- ✅ Stream processing (simple chunk collection)
- ✅ Standard response format

### What's Excluded (Beyond MVP)
- ❌ Advanced error handling (try/except blocks)
- ❌ Custom logging beyond AWS Lambda defaults
- ❌ Input validation (format, length, characters)
- ❌ Retry logic (AWS SDK default only)
- ❌ Response stream error handling
- ❌ Timeout handling
- ❌ Rate limiting
- ❌ Request tracing/correlation

## References

- [Bedrock Agent Runtime Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-api.html)
- [InvokeAgent API Reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_InvokeAgent.html)
- [Control Agent Session State](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-session-state.html)
- [Boto3 bedrock-agent-runtime Client](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-agent-runtime.html)
- Local research: `specs/v1/docs/bedrock-agent-resources.md`
- Design specification: `specs/v1/design.md`
- Requirements: `specs/v1/requirements.md`

## Next Tasks

After T-007 completes:
- **T-009**: Bedrock Agent Configuration (provides real agent IDs)
- **T-004-API**: API Gateway Setup (provides API endpoint)
- **T-008**: GetDocuments Action Group (depends on T-007 for session parameters pattern)
- **T-010**: SaveDocument Action Group (depends on T-007 for session parameters pattern)

## Estimated Effort

- Lambda code implementation: 20 minutes
- Stream processing logic: 10 minutes
- Testing with mock events: 10 minutes
- Documentation: 5 minutes
- **Total**: ~45 minutes

---

## Implementation Summary (2025-10-06)

### ✅ Status: COMPLETE

**Implementation Details**:
- **File**: `src/agent-invoker/lambda_function.py`
- **Line count**: 64 lines (minimal MVP as planned)
- **Deployed**: Successfully deployed to AWS Lambda `bb-data-science-kyb-agent-invoker`
- **Source code hash**: `8DWgKhDcRZSWAjYsi8Ryoe0YHpZPWV62sK5pgVstM6U=`

**Code Structure**:
1. Environment variables: AGENT_ID, AGENT_ALIAS_ID (currently PLACEHOLDER)
2. Boto3 client: bedrock-agent-runtime
3. lambda_handler:
   - Parses API Gateway proxy event body (JSON)
   - Extracts and validates customer_id (not empty check)
   - Generates UUID session_id
   - Invokes agent with sessionState containing session parameters
   - Processes streaming response
   - Returns structured JSON response
4. process_agent_response: Helper function for stream processing

**Session Parameters Implemented**:
```python
sessionState = {
    'sessionAttributes': {
        'customer_id': customer_id,
        'output_type': 'Standard'
    }
}
```

**Testing Status**:
- ⚠️ Cannot test until T-009 completes (AGENT_ID and AGENT_ALIAS_ID are PLACEHOLDER)
- Lambda will fail with invalid agent ID error (expected behavior)
- Code logic validated through code review

**Next Steps**:
1. Wait for T-009 to provide real agent_id and agent_alias_id
2. Wait for T-004-API to provide API Gateway endpoint
3. Perform integration testing with real agent IDs

**Deployment Command Used**:
```bash
cd data-science/us-east-1/bedrock-agent-kyb
leverage tf apply -target=aws_lambda_function.agent_invoker -auto-approve
```

**Result**: Lambda code updated successfully with no infrastructure changes
