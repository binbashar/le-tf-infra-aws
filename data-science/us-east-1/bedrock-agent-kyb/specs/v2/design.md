# KYB Agent Design v2

## Components

**S3 Buckets:**
- Input bucket (for PDF uploads)
- Processing bucket (for BDA custom and standard output)
- Output bucket (for final agent results)

**Lambda Functions:**
- BDA Invoker Lambda (triggers BDA processing)
- Agent Invoker Lambda (triggers Bedrock Agent)
- GetDocuments Lambda (action group - retrieves from processing bucket)
- CheckSanctions Lambda (action group - queries external sanctions API)
- SaveDocument Lambda (action group - saves to output bucket)

**EventBridge:**
- Rule 1: Input bucket ObjectCreated → BDA Invoker Lambda

**API Gateway:**
- REST API endpoint: POST /invoke-agent
- Authentication: AWS IAM (SigV4 request signing required)
- Two-policy access control: Resource policy + Identity-based policy
- Accepts customer_id parameter in request body
- Integrates with Agent Invoker Lambda via AWS_PROXY
- Managed IAM policy for SSO permission set attachment

**Bedrock Resources:**
- BDA Project (with custom and standard output configuration)
- Bedrock Agent (with session parameters support, 3 action groups)

## Data Flow

```
1. PDF → Input Bucket (with customer_id prefix: {customer_id}/document.pdf)
2. EventBridge → BDA Invoker Lambda → BDA Project
3. BDA → Custom + Standard Output → Processing Bucket (preserves customer_id prefix)
4. API Gateway (receives customer_id) → Agent Invoker Lambda → Bedrock Agent (with customer_id session param)
5. Agent → Action Group: GetDocuments Lambda (uses customer_id prefix) → Processing Bucket (both outputs)
6. Agent → Action Group: CheckSanctions Lambda → External Sanctions API
7. Agent → Action Group: SaveDocument Lambda → Output Bucket
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
- Invokes BDA with custom and standard output configuration

**Agent Invoker:**
- Triggered by IAM-authenticated API Gateway POST requests
- Extracts customer_id from request body
- Validates request is properly authenticated via IAM
- Invokes Bedrock Agent with session parameters (customer_id)
- Returns agent invocation status and session ID

**GetDocuments (Action Group):**
- Receives session parameters automatically (customer_id)
- Retrieves both custom and standard output for all documents
- Uses customer_id as S3 prefix: `customers/{customer_id}/`
- Returns unified document list with both extraction types

**CheckSanctions (Action Group):**
- Receives session parameters automatically (customer_id)
- Accepts `name` + `surname` OR `document_id` parameters
- Returns mocked random sanctions data (demo mode - no external API)
- Returns JSON with `num_sanctions` and `pep_score`

**SaveDocument (Action Group):**
- Receives session parameters automatically (customer_id)
- Receives KYB verdict in request body `content` parameter
- Saves verdict to output bucket with Athena-queryable partitioning: `{customer_id}/yyyy=YYYY/mm=MM/dd=DD/{uuid}.json`

## Action Group Interfaces

**GetDocuments Schema:**
```yaml
paths:
  /documents:
    get:
      description: Retrieve both custom and standard output documents
```

**CheckSanctions Schema:**
```yaml
paths:
  /sanctions:
    get:
      parameters:
        - name: name
          in: query
          schema:
            type: string
        - name: surname
          in: query
          schema:
            type: string
        - name: document_id
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
```

**Session Parameters:**
- `customer_id`: Passed from Agent Invoker Lambda

## API Gateway Endpoint

**Endpoint:** POST /invoke-agent

**Authentication:** AWS IAM (SigV4 signing required)

**Access Control Model:**
AWS IAM authentication uses a **two-policy requirement** for defense-in-depth security:

1. **Resource Policy** (API Gateway): Allows same-account principals to invoke
2. **Identity-Based Policy** (IAM Principal): Grants `execute-api:Invoke` permission

Both policies must allow for a request to succeed. This provides granular control while maintaining account-level boundaries.

**Operational Access:**
- IaC creates a managed IAM policy automatically
- Admin attaches policy to SSO permission sets (one-time per environment)
- All users with that permission set can invoke the API

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

## Demo Mode Implementation

**CheckSanctions Mocked Data:**
- No external API integration (demo purposes only)
- Mocking function isolated in `get_mocked_sanctions_data()` for easy API replacement
- Random scenarios: clean records (0 sanctions), medium/high PEP scores, records with sanctions
- Deterministic randomization based on query_value hash for consistent demo results
- No environment variables, Secrets Manager, or external networking required
