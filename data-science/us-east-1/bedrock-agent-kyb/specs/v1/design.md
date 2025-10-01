# KYB Agent Design

## Components

**S3 Buckets:**
- Input bucket (for PDF uploads)
- Processing bucket (for BDA standard output)
- Output bucket (for final agent results)

**Lambda Functions:**
- BDA Invoker Lambda (triggers BDA processing)
- Agent Invoker Lambda (triggers Bedrock Agent)
- GetDocuments Lambda (action group - retrieves from processing bucket)
- SaveDocument Lambda (action group - saves to output bucket)

**EventBridge:**
- Rule 1: Input bucket ObjectCreated → BDA Invoker Lambda

**API Gateway:**
- REST API endpoint: POST /invoke-agent
- Authentication: AWS IAM (SigV4 request signing required)
- Accepts customer_id parameter in request body
- Integrates with Agent Invoker Lambda
- Default access: Any IAM principal in same AWS account

**Bedrock Resources:**
- BDA Project (with standard output configuration)
- Bedrock Agent (with session parameters support)

## Data Flow

```
1. PDF → Input Bucket (with customer_id prefix: {customer_id}/document.pdf)
2. EventBridge → BDA Invoker Lambda → BDA Project
3. BDA → Standard Output → Processing Bucket (preserves customer_id prefix)
4. API Gateway (receives customer_id) → Agent Invoker Lambda → Bedrock Agent (with customer_id session param)
5. Agent → Action Group: GetDocuments Lambda (uses customer_id prefix) → Processing Bucket
6. Agent → Action Group: SaveDocument Lambda → Output Bucket
```

## OpenTofu Files

- `config.tf` - Provider and backend configuration
- `locals.tf` - Local variables and naming
- `variables.tf` - Input variables
- `outputs.tf` - Layer outputs
- `s3.tf` - S3 buckets and policies
- `bedrock.tf` - BDA project and Bedrock Agent
- `lambda.tf` - Lambda functions and layers
- `eventbridge.tf` - EventBridge rule for input bucket trigger
- `api_gateway.tf` - API Gateway REST API and Lambda integration
- `iam.tf` - IAM roles and policies

## Lambda Functions

**BDA Invoker:**
- Triggered by input bucket events
- Invokes BDA with standard output configuration
- Generates correlation ID for tracking

**Agent Invoker:**
- Triggered by IAM-authenticated API Gateway POST requests
- Extracts customer_id from request body
- Validates request is properly authenticated via IAM
- Invokes Bedrock Agent with session parameters (customer_id, output_type="Standard")
- Returns agent invocation status and session ID

**GetDocuments (Action Group):**
- Receives session parameters automatically (customer_id, output_type)
- Uses customer_id as S3 prefix: `standard/{customer_id}/`
- Retrieves documents from processing bucket using customer-specific path
- Returns list of documents and their content

**SaveDocument (Action Group):**
- Receives session parameters automatically
- Saves processed results to output bucket
- Maintains correlation ID in metadata

## Action Group Interfaces

**GetDocuments Schema:**
```yaml
paths:
  /documents:
    get:
      parameters:
        - name: key_pattern
          in: query
          schema:
            type: string
```

**SaveDocument Schema:**
```yaml
paths:
  /save:
    post:
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                content:
                  type: string
                key:
                  type: string
```

**Session Parameters:**
- `customer_id`: Passed from API Gateway request
- `output_type`: "Standard"

## API Gateway Endpoint

**Endpoint:** POST /invoke-agent

**Authentication:** AWS IAM (SigV4 signing required)

**Access:** Any IAM principal (user, role) in the same AWS account

**Request Body:**
```json
{
  "customer_id": "string (required)"
}
```

**Response:**
```json
{
  "status": "success|error",
  "session_id": "string",
  "agent_id": "string",
  "message": "string"
}
```

**Example Test Command:**
```bash
# Requires awscurl (pip install awscurl)
awscurl --service execute-api -X POST \
  -d '{"customer_id":"test-123"}' \
  -H "Content-Type: application/json" \
  "https://your-api-id.execute-api.us-east-1.amazonaws.com/v1/invoke-agent"
```