# T-010: SaveDocument Action Group Implementation Plan

**Task**: Replace mock with production S3 save for KYB verdicts
**Requirements**: REQ-004
**Dependencies**: T-005 (Lambda infrastructure), T-009 (Bedrock Agent)
**Date**: 2025-10-13

## Objective

Replace mock implementation with production code that saves KYB verdicts to output bucket using Athena-queryable partitioning.

## Current State

### Infrastructure
- ✅ Lambda deployed: `aws_lambda_function.save_document`
- ✅ IAM permissions: S3 PutObject on output bucket
- ✅ Action group registered in Bedrock Agent
- ✅ OpenAPI schema: `src/schemas/save_document.yaml`

### Code Status
- ⚠️ **MOCK implementation** (135 lines)
- ✅ Session parameters extraction (customer_id)
- ✅ Request body parsing (`content`, `document_key`)
- ✅ Bedrock agent response format
- ❌ No real S3 PutObject (lines 36-55 are mock)

## Technical Design

### Input
**Agent sends verdict via action group**:
- Session parameter: `customer_id`
- Request body: `content` (KYB verdict JSON/string), `document_key` (optional)

### Output Structure
```
s3://output-bucket/
└── {customer_id}/
    └── yyyy=2025/
        └── mm=10/
            └── dd=13/
                └── {uuid}.json
```

**Athena-queryable partitioning** enables SQL queries like:
```sql
SELECT * FROM verdicts
WHERE customer_id = 'acme-corp'
  AND yyyy = '2025'
  AND mm = '10'
```

## Implementation Steps

### Step 1: Update Lambda Code

**File**: `src/save-document/lambda_function.py`

**Changes**:

1. **Add boto3 S3 client** (after line 3):
```python
import uuid
import boto3

s3_client = boto3.client('s3')
```

2. **Replace mock save** (lines 36-62) with real implementation:
```python
# Generate Athena-queryable S3 key
now = datetime.utcnow()
file_uuid = str(uuid.uuid4())
s3_key = f"{customer_id}/yyyy={now.year}/mm={now.month:02d}/dd={now.day:02d}/{file_uuid}.json"

# Save to S3
s3_client.put_object(
    Bucket=OUTPUT_BUCKET,
    Key=s3_key,
    Body=json.dumps(document_data, default=str, indent=2),
    ContentType='application/json'
)

# Build response
response_body = {
    'status': 'success',
    'customer_id': customer_id,
    's3_key': s3_key,
    'timestamp': now.isoformat()
}
```

3. **Update docstring** (line 8): Remove "Mock" reference

4. **Simplify logging**: Remove excessive debug messages

**Target**: ~85-95 lines (current: 135 lines)

### Step 2: Deploy

```bash
cd data-science/us-east-1/bedrock-agent-kyb
leverage tf apply -target=aws_lambda_function.save_document -auto-approve
```

### Step 3: Test

**Test Event**: `testing/events/save-document-test-event.json`
```json
{
  "messageVersion": "1.0",
  "sessionAttributes": {
    "customer_id": "test-customer-123"
  },
  "actionGroup": "SaveDocument",
  "apiPath": "/documents",
  "httpMethod": "POST",
  "requestBody": {
    "content": {
      "application/json": {
        "properties": [
          {
            "name": "content",
            "value": "{\"verdict\":\"approved\",\"confidence\":0.95}"
          }
        ]
      }
    }
  }
}
```

**Verification**:
```bash
# List saved verdicts
leverage aws s3 ls s3://{output-bucket}/test-customer-123/yyyy=2025/ --recursive

# Download verdict
leverage aws s3 cp s3://{output-bucket}/test-customer-123/yyyy=2025/mm=10/dd=13/{uuid}.json -
```

## Success Criteria

- [ ] boto3 S3 client added
- [ ] Real S3 PutObject replaces mock
- [ ] Athena partitioning: `{customer_id}/yyyy=YYYY/mm=MM/dd=DD/{uuid}.json`
- [ ] Response excludes 'mock' field
- [ ] Code ~85-95 lines (minimal pattern)
- [ ] Lambda deployed successfully
- [ ] S3 object saved and retrievable

## References

- OpenAPI schema: `src/schemas/save_document.yaml`
- GetDocuments reference: `src/get-documents/lambda_function.py`
- Design: `specs/v1/design.md`
- Requirements: `specs/v1/requirements.md`
