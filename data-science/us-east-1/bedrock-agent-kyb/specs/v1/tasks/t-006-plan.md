# T-006: BDA Invoker Lambda Implementation Plan

**Task**: Implement Lambda function that triggers BDA processing
**Requirements**: REQ-001, REQ-002
**Dependencies**: T-005 (Lambda infrastructure)
**Date**: 2025-10-06

## Objective

Implement minimal MVP Lambda code for `bda-invoker` that:
1. Handles S3 ObjectCreated events from EventBridge
2. Extracts customer_id from S3 object key prefix
3. Generates correlation_id for end-to-end tracking
4. Invokes BDA with standard output configuration
5. Stores processing metadata in processing bucket

## Current State Analysis

### Existing Infrastructure
- ✅ Lambda function deployed: `aws_lambda_function.bda_invoker`
- ✅ EventBridge rule configured for `.pdf` uploads to input bucket
- ✅ IAM role with basic permissions (CloudWatch, S3 GetObject, BDA invoke)
- ✅ BDA project with standard output configuration
- ✅ Placeholder Lambda code exists at `src/bda-invoker/lambda_function.py`

### Environment Variables Available
```python
BDA_PROJECT_ARN   = "arn:aws:bedrock:region:account:data-automation/project-id"
INPUT_BUCKET      = "bucket-name"
PROCESSING_BUCKET = "bucket-name"
LOG_LEVEL         = "INFO"
```

## Technical Design

### Event Flow
```
S3 Upload (.pdf) → EventBridge Rule → BDA Invoker Lambda → BDA Project
                                            ↓
                                    Processing Bucket (metadata)
```

### EventBridge Event Structure
```json
{
  "version": "0",
  "source": "aws.s3",
  "detail-type": "Object Created",
  "detail": {
    "bucket": {
      "name": "input-bucket-name"
    },
    "object": {
      "key": "customer123/invoice.pdf",
      "size": 12345,
      "etag": "abc123"
    }
  }
}
```

### Customer ID Extraction Pattern
```
S3 Key Format: {customer_id}/{filename}.pdf
Examples:
  - "customer123/invoice.pdf" → customer_id = "customer123"
  - "acme-corp/document.pdf"  → customer_id = "acme-corp"
  - "test.pdf"                → customer_id = "unknown"
```

### BDA Invocation API

**Boto3 Client**: `bedrock-data-automation-runtime`
**Method**: `invoke_data_automation_async()`

**Required Parameters**:
```python
{
    'dataAutomationProfileArn': 'arn:aws:bedrock:region:account:data-automation-profile/profile-id',
    'inputConfiguration': {
        's3Uri': 's3://input-bucket/customer123/invoice.pdf'
    },
    'outputConfiguration': {
        's3Uri': 's3://processing-bucket/standard/{customer_id}/'
    },
    'dataAutomationConfiguration': {
        'dataAutomationProjectArn': 'arn:aws:bedrock:region:account:data-automation/project-id',
        'stage': 'LIVE'
    }
}
```

**Response**:
```python
{
    'invocationArn': 'arn:aws:bedrock:region:account:data-automation-invocation/inv-id'
}
```

### Output Structure in Processing Bucket
```
s3://processing-bucket/
└── standard/
    └── {customer_id}/
        ├── metadata.json              # Correlation tracking (created by Lambda)
        └── {document-id}/             # BDA standard output (created by BDA)
            ├── document_metadata.json
            ├── extracted_text.txt
            ├── extracted_text.md
            └── extracted_text.csv
```

### Metadata JSON Format
```json
{
  "correlation_id": "uuid-v4-string",
  "customer_id": "customer123",
  "input_bucket": "input-bucket-name",
  "input_key": "customer123/invoice.pdf",
  "input_etag": "abc123",
  "invocation_arn": "arn:aws:bedrock:...",
  "timestamp": "2025-10-06T12:34:56Z",
  "status": "initiated"
}
```

## Implementation Steps

### Step 1: Update S3 Bucket Policies (s3.tf)

**Required Changes**:

1. **Input Bucket Policy** - Allow BDA to read uploaded PDFs:
```hcl
{
  Sid    = "AllowBedrockDataAutomationRead"
  Effect = "Allow"
  Principal = {
    Service = "bedrock.amazonaws.com"
  }
  Action = [
    "s3:GetObject",
    "s3:GetObjectVersion",
    "s3:ListBucket"
  ]
  Resource = [
    aws_s3_bucket.input.arn,
    "${aws_s3_bucket.input.arn}/*"
  ]
}
```

2. **Processing Bucket Policy** - Allow BDA to write extraction results:
```hcl
{
  Sid    = "AllowBedrockDataAutomationWrite"
  Effect = "Allow"
  Principal = {
    Service = "bedrock.amazonaws.com"
  }
  Action = [
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:GetObject",
    "s3:GetObjectVersion",
    "s3:DeleteObject",
    "s3:ListBucket"
  ]
  Resource = [
    aws_s3_bucket.processing.arn,
    "${aws_s3_bucket.processing.arn}/*"
  ]
}
```

### Step 1b: Update IAM Permissions (iam.tf)

**Current Issue**: BDA invoker role lacks S3 PutObject permission for processing bucket

**Required Change**:
```hcl
# In data "aws_iam_policy_document" "bda_invoker_policy"
statement {
  sid       = "S3ProcessingBucketAccess"
  effect    = "Allow"
  actions   = ["s3:PutObject"]
  resources = ["${aws_s3_bucket.processing.arn}/*"]
}
```

### Step 2: Implement Lambda Handler (src/bda-invoker/lambda_function.py)

**Minimal MVP Code Structure**:
```python
import json
import os
import boto3
from uuid import uuid4
from datetime import datetime

# Environment variables
BDA_PROJECT_ARN = os.environ['BDA_PROJECT_ARN']
PROCESSING_BUCKET = os.environ['PROCESSING_BUCKET']
# TODO: Add BDA_PROFILE_ARN to environment variables

# Boto3 clients
bda_client = boto3.client('bedrock-data-automation-runtime')
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Extract S3 event details
    bucket_name = event['detail']['bucket']['name']
    object_key = event['detail']['object']['key']
    object_etag = event['detail']['object'].get('etag', '')

    # Extract customer_id from key prefix
    customer_id = extract_customer_id(object_key)

    # Generate correlation_id
    correlation_id = str(uuid4())

    # Invoke BDA
    input_s3_uri = f"s3://{bucket_name}/{object_key}"
    output_s3_uri = f"s3://{PROCESSING_BUCKET}/customers/{customer_id}/"

    response = bda_client.invoke_data_automation_async(
        dataAutomationProfileArn='PLACEHOLDER',  # TODO: Configure profile ARN
        inputConfiguration={'s3Uri': input_s3_uri},
        outputConfiguration={'s3Uri': output_s3_uri},
        dataAutomationConfiguration={
            'dataAutomationProjectArn': BDA_PROJECT_ARN,
            'stage': 'LIVE'
        }
    )

    invocation_arn = response['invocationArn']

    # Store metadata
    metadata = {
        'correlation_id': correlation_id,
        'customer_id': customer_id,
        'input_bucket': bucket_name,
        'input_key': object_key,
        'input_etag': object_etag,
        'invocation_arn': invocation_arn,
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'status': 'initiated'
    }

    metadata_key = f"customers/{customer_id}/metadata.json"
    s3_client.put_object(
        Bucket=PROCESSING_BUCKET,
        Key=metadata_key,
        Body=json.dumps(metadata),
        ContentType='application/json'
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'correlation_id': correlation_id,
            'invocation_arn': invocation_arn
        })
    }

def extract_customer_id(key):
    """Extract customer_id from S3 key prefix"""
    parts = key.split('/')
    return parts[0] if len(parts) > 1 else 'unknown'
```

**Minimal Approach Notes**:
- No try/except blocks (AWS SDK handles retries)
- No custom logging beyond AWS Lambda default
- No input validation (S3/EventBridge guarantees event structure)
- No status checking (handled by EventBridge in later tasks)

### Step 3: Update Lambda Environment Variables (lambda.tf)

**Add BDA Profile ARN**:
```hcl
resource "aws_lambda_function" "bda_invoker" {
  # ... existing configuration ...

  environment {
    variables = {
      BDA_PROJECT_ARN   = awscc_bedrock_data_automation_project.kyb_agent.project_arn
      BDA_PROFILE_ARN   = "PLACEHOLDER"  # TODO: Configure or create profile
      INPUT_BUCKET      = aws_s3_bucket.input.id
      PROCESSING_BUCKET = aws_s3_bucket.processing.id
      LOG_LEVEL         = "INFO"
    }
  }
}
```

### Step 4: Configure BDA Profile ARN

**RESOLVED**: BDA uses AWS-managed default profiles available in multiple regions.

**Key Findings**:
1. **Default Profile ARN Pattern**: `arn:aws:bedrock:{region}:*:data-automation-profile/us.data-automation-v1`
2. **Multi-Region Requirement**: BDA can invoke profiles across regions even when Lambda runs in single region
3. **No Custom Profile Needed**: AWS provides default profiles, no need to create custom resource

**IAM Policy Requirements** (from reference layer `bedrock-kyb-bda`):
- Must grant access to BDA profiles in **multiple regions**: `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`
- Use wildcard for account ID: `*` (more flexible than hardcoded account)
- Use wildcard suffix: `/*` to match any profile name

**Example IAM Policy** (proven pattern):
```hcl
statement {
  sid    = "BDAAccess"
  effect = "Allow"
  actions = [
    "bedrock:InvokeDataAutomationAsync",
    "bedrock:GetDataAutomationStatus"
  ]
  resources = [
    "arn:aws:bedrock:us-east-1:*:data-automation-project/*",
    "arn:aws:bedrock:us-east-1:*:data-automation-profile/*",
    "arn:aws:bedrock:us-east-2:*:data-automation-profile/*",
    "arn:aws:bedrock:us-west-1:*:data-automation-profile/*",
    "arn:aws:bedrock:us-west-2:*:data-automation-profile/*"
  ]
}
```

**Why Multi-Region**:
- BDA service may route requests to different regions for load balancing or availability
- Even with `region_name='us-east-1'` in boto3, BDA can use cross-region profiles
- Observed in testing: Lambda in `us-east-1` attempted to use `us-east-2` profile

### Step 5: Deploy and Test

**Deployment Commands**:
```bash
cd data-science/us-east-1/bedrock-agent-kyb

# Format and validate
leverage tf format
leverage tf validate

# Plan changes
leverage tf plan -target=aws_iam_policy.bda_invoker_policy \
                 -target=aws_lambda_function.bda_invoker

# Apply changes
leverage tf apply -target=aws_iam_policy.bda_invoker_policy \
                  -target=aws_lambda_function.bda_invoker
```

**Test Procedure**:
```bash
# Get input bucket name
INPUT_BUCKET=$(leverage tf output -raw input_bucket_name)

# Upload test PDF
echo "Test PDF content" > test.pdf
aws s3 cp test.pdf s3://${INPUT_BUCKET}/test-customer/test-document.pdf

# Check Lambda logs
aws logs tail /aws/lambda/bb-data-science-bda-invoker --follow

# Verify metadata in processing bucket
PROCESSING_BUCKET=$(leverage tf output -raw processing_bucket_name)
aws s3 ls s3://${PROCESSING_BUCKET}/standard/test-customer/

# Check metadata content
aws s3 cp s3://${PROCESSING_BUCKET}/standard/test-customer/metadata.json -
```

## Success Criteria

- [ ] Lambda handles EventBridge events from input bucket
- [ ] customer_id correctly extracted from S3 key prefix
- [ ] correlation_id generated and stored
- [ ] BDA invocation succeeds (returns invocationArn)
- [ ] Metadata JSON written to processing bucket
- [ ] BDA standard output appears in processing bucket
- [ ] No errors in CloudWatch logs

## Blockers and Risks

### Critical Blocker: BDA Profile ARN
- **Issue**: `dataAutomationProfileArn` is required parameter but not configured
- **Impact**: Lambda will fail on BDA invocation without valid profile ARN
- **Resolution**: Research BDA profile requirements, add to bedrock.tf if needed

### Minimal Risk: Error Handling
- **Trade-off**: MVP approach skips error handling for simplicity
- **Impact**: Any API errors will result in Lambda failure (acceptable for MVP)
- **Future**: Add error handling in production refinement phase

## References

- [BDA Invocation API Documentation](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_data-automation-runtime_InvokeDataAutomationAsync.html)
- [BDA Runtime Boto3 Client](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-data-automation-runtime.html)
- [Using BDA API Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/bda-using-api.html)
- Local research: `specs/v1/docs/bda-invocation-api.md`

## Next Tasks

- **T-007**: Agent Invoker Lambda Code (depends on T-009 for agent IDs)
- **T-008**: GetDocuments Action Group (depends on this task for metadata format)
- **T-009**: Bedrock Agent Configuration (can proceed in parallel)

## Estimated Effort

- IAM updates: 5 minutes
- Lambda implementation: 20 minutes
- BDA profile research/config: 15 minutes (unknown variable)
- Testing and validation: 15 minutes
- **Total**: ~55 minutes (excluding profile ARN research time)
