# Bedrock KYB Agent Layer

Document processing pipeline combining AWS Bedrock Data Automation with Bedrock Agent for KYB document extraction.

## Architecture

**Pipeline Flow:**
1. PDF → Input S3 Bucket
2. EventBridge → BDA Invoker Lambda → BDA Project
3. BDA Standard Output → Processing S3 Bucket
4. API Gateway → Agent Invoker Lambda → Bedrock Agent
5. Agent → GetDocuments Lambda → Processing Bucket
6. Agent → SaveDocument Lambda → Output Bucket

## API Gateway Usage

### Endpoint

```
POST https://{api-id}.execute-api.us-east-1.amazonaws.com/v1/invoke-agent
```

Get actual endpoint:
```bash
leverage tf output api_gateway_endpoint
```

### Authentication

Requires AWS IAM authentication (SigV4 request signing).

### Request

```json
{
  "customer_id": "string (required)"
}
```

### Response

```json
{
  "status": "success|error",
  "session_id": "string",
  "agent_id": "string",
  "message": "string"
}
```

## SSO Access Setup

Grant API access to SSO users (one-time per environment):

1. Get policy ARN:
   ```bash
   leverage tf output api_invoke_policy_arn
   ```

2. Open IAM Identity Center console

3. Navigate to: Permission sets

4. Select permission set (e.g., DataScientist)

5. Click: Permissions tab → Add permissions → Attach policies

6. Search for: `bb-data-science-kyb-agent-api-invoke`

7. Attach policy

All users with this permission set can now invoke the API using their SSO credentials.

## Testing

### Install awscurl

```bash
pip install awscurl
```

### Test API Invocation

```bash
# Get endpoint URL
ENDPOINT=$(leverage tf output -raw api_gateway_endpoint)

# Invoke API
awscurl --service execute-api -X POST \
  -d '{"customer_id":"test-customer-123"}' \
  -H "Content-Type: application/json" \
  "$ENDPOINT"
```

### Expected Responses

**Success (200):**
```json
{
  "status": "success",
  "session_id": "...",
  "agent_id": "...",
  "message": "Agent invocation started"
}
```

**Validation Error (400):**
```json
{
  "message": "Invalid request body"
}
```

**Authentication Error (403):**
```json
{
  "Message": "User: ... is not authorized to perform: execute-api:Invoke"
}
```

## Deployment

```bash
cd data-science/us-east-1/bedrock-agent-kyb

leverage tf init
leverage tf plan
leverage tf apply
```

## Outputs

Key infrastructure values:
- `api_gateway_endpoint` - API endpoint URL
- `api_gateway_id` - API Gateway REST API ID
- `api_invoke_policy_arn` - IAM policy ARN for SSO attachment
- `input_bucket_name` - S3 bucket for PDF uploads
- `processing_bucket_name` - S3 bucket for BDA output
- `output_bucket_name` - S3 bucket for final results
