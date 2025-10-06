# AWS Bedrock Data Automation - Lambda Invocation API
*Generated: 2025-01-06*

## Objective
Quick reference for invoking AWS Bedrock Data Automation (BDA) projects from Lambda functions using boto3.

## Quick Findings
- **Primary AWS Service**: bedrock-data-automation-runtime
- **Boto3 Client Name**: `bedrock-data-automation-runtime`
- **Key Methods**: `invoke_data_automation_async()` and `get_data_automation_status()`
- **Processing Model**: Asynchronous with S3-based input/output
- **Implementation Complexity**: Medium

## Essential Resources

### API Documentation
- [InvokeDataAutomationAsync API Reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_data-automation-runtime_InvokeDataAutomationAsync.html)
- [GetDataAutomationStatus API Reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_data-automation-runtime_GetDataAutomationStatus.html)
- [Using the Bedrock Data Automation API](https://docs.aws.amazon.com/bedrock/latest/userguide/bda-using-api.html)
- [Boto3 Documentation - bedrock-data-automation-runtime](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-data-automation-runtime.html)

## Boto3 Client Setup

```python
import boto3

# Create the BDA Runtime client
client = boto3.client('bedrock-data-automation-runtime')
```

## API Method: invoke_data_automation_async

### Purpose
Initiates asynchronous processing of files with a BDA project. Returns an invocation ARN for tracking.

### Method Signature
```python
response = client.invoke_data_automation_async(
    dataAutomationProfileArn='string',  # REQUIRED
    inputConfiguration={                 # REQUIRED
        's3Uri': 'string',
        'assetProcessingConfiguration': {
            'video': {
                'segmentConfiguration': {...}
            }
        }
    },
    outputConfiguration={                # REQUIRED
        's3Uri': 'string'
    },
    dataAutomationConfiguration={       # Optional
        'dataAutomationProjectArn': 'string',
        'stage': 'string'
    },
    blueprints=[                        # Optional
        {
            'blueprintArn': 'string',
            'stage': 'string',
            'version': 'string'
        }
    ],
    notificationConfiguration={         # Optional
        'eventBridgeConfiguration': {
            'eventBridgeEnabled': True|False
        }
    },
    encryptionConfiguration={           # Optional
        'kmsKeyId': 'string',
        'kmsEncryptionContext': {
            'string': 'string'
        }
    },
    clientToken='string',               # Optional (idempotency)
    tags=[                              # Optional
        {
            'key': 'string',
            'value': 'string'
        }
    ]
)
```

### Required Parameters

1. **dataAutomationProfileArn** (string, required)
   - ARN of the profile calling your request
   - Pattern: `arn:aws:bedrock:[region]:[account]:data-automation-profile/[profile-id]`

2. **inputConfiguration** (dict, required)
   - **s3Uri**: S3 location of input file(s) to process
   - Format: `s3://bucket-name/path/to/file`

3. **outputConfiguration** (dict, required)
   - **s3Uri**: S3 location for output files
   - Results will be written to this location

### Optional Parameters

- **dataAutomationConfiguration**: Specify project ARN for standard output
- **blueprints**: List of blueprint ARNs for custom output (max 40)
- **notificationConfiguration**: Enable EventBridge notifications
- **encryptionConfiguration**: KMS encryption settings
- **clientToken**: Idempotency token (prevents duplicate calls)
- **tags**: Resource tags

### Response Structure
```python
{
    'invocationArn': 'arn:aws:bedrock:[region]:[account]:data-automation-invocation/[invocation-id]'
}
```

## API Method: get_data_automation_status

### Purpose
Retrieves the status of an asynchronous BDA invocation and the output location when complete.

### Method Signature
```python
response = client.get_data_automation_status(
    invocationArn='string'  # REQUIRED
)
```

### Response Structure
```python
{
    'status': 'Created'|'InProgress'|'Success'|'ServiceError'|'ClientError',
    'outputConfiguration': {
        's3Uri': 'string'  # Available when status is 'Success'
    },
    'errorType': 'string',     # Present if error occurred
    'errorMessage': 'string'    # Present if error occurred
}
```

### Status Values
- **Created**: Job has been created but not started
- **InProgress**: Job is currently processing
- **Success**: Job completed successfully (output available)
- **ServiceError**: Internal service error occurred
- **ClientError**: Client-side error (e.g., invalid input)

## Lambda Implementation Examples

### Basic Invocation Pattern
```python
import json
import boto3

def lambda_handler(event, context):
    client = boto3.client('bedrock-data-automation-runtime')

    # Extract parameters from event
    input_s3_uri = event['inputS3Uri']
    output_s3_uri = event['outputS3Uri']
    project_arn = event['projectArn']
    profile_arn = event['profileArn']

    try:
        # Invoke BDA asynchronously
        response = client.invoke_data_automation_async(
            dataAutomationProfileArn=profile_arn,
            inputConfiguration={
                's3Uri': input_s3_uri
            },
            outputConfiguration={
                's3Uri': output_s3_uri
            },
            dataAutomationConfiguration={
                'dataAutomationProjectArn': project_arn
            }
        )

        invocation_arn = response['invocationArn']

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'BDA invocation started',
                'invocationArn': invocation_arn
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
```

### Status Checking Pattern
```python
import json
import boto3

def lambda_handler(event, context):
    client = boto3.client('bedrock-data-automation-runtime')

    invocation_arn = event['invocationArn']

    try:
        response = client.get_data_automation_status(
            invocationArn=invocation_arn
        )

        status = response['status']
        result = {
            'status': status
        }

        if status == 'Success':
            result['outputLocation'] = response['outputConfiguration']['s3Uri']
        elif status in ['ServiceError', 'ClientError']:
            result['error'] = {
                'type': response.get('errorType'),
                'message': response.get('errorMessage')
            }

        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
```

### EventBridge Integration Pattern
```python
def lambda_handler(event, context):
    client = boto3.client('bedrock-data-automation-runtime')

    # Enable EventBridge notifications for async tracking
    response = client.invoke_data_automation_async(
        dataAutomationProfileArn=event['profileArn'],
        inputConfiguration={
            's3Uri': event['inputS3Uri']
        },
        outputConfiguration={
            's3Uri': event['outputS3Uri']
        },
        dataAutomationConfiguration={
            'dataAutomationProjectArn': event['projectArn']
        },
        notificationConfiguration={
            'eventBridgeConfiguration': {
                'eventBridgeEnabled': True
            }
        },
        clientToken=context.request_id  # Use Lambda request ID for idempotency
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'invocationArn': response['invocationArn']
        })
    }
```

## Event Structure for Lambda

### Input Event for Invocation
```json
{
    "profileArn": "arn:aws:bedrock:us-east-1:123456789012:data-automation-profile/profile-id",
    "projectArn": "arn:aws:bedrock:us-east-1:123456789012:data-automation/project-id",
    "inputS3Uri": "s3://my-bucket/input/document.pdf",
    "outputS3Uri": "s3://my-bucket/output/",
    "enableEventBridge": true
}
```

### Input Event for Status Check
```json
{
    "invocationArn": "arn:aws:bedrock:us-east-1:123456789012:data-automation-invocation/inv-12345"
}
```

## Output Configuration

### Standard Output Structure
The output is written to the specified S3 location with structured JSON format based on the modality:

```json
{
    "metadata": {
        "id": "document_123",
        "semantic_modality": "DOCUMENT|IMAGE|VIDEO|AUDIO",
        "s3_bucket": "output-bucket",
        "s3_prefix": "output/path/"
    },
    "document|image|video|audio": {
        // Modality-specific extraction results
        "summary": "...",
        "extracted_text": "...",
        "custom_fields": {...}
    }
}
```

## IAM Requirements

### Lambda Execution Role

Lambda execution role must include:

**IMPORTANT**: BDA can use profiles in multiple regions regardless of Lambda's region. Always include multi-region profile permissions.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BDAAccess",
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeDataAutomationAsync",
                "bedrock:GetDataAutomationStatus"
            ],
            "Resource": [
                "arn:aws:bedrock:us-east-1:*:data-automation-project/*",
                "arn:aws:bedrock:us-east-1:*:data-automation-profile/*",
                "arn:aws:bedrock:us-east-2:*:data-automation-profile/*",
                "arn:aws:bedrock:us-west-1:*:data-automation-profile/*",
                "arn:aws:bedrock:us-west-2:*:data-automation-profile/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::input-bucket/*",
                "arn:aws:s3:::processing-bucket/*"
            ]
        }
    ]
}
```

### S3 Bucket Policies

**CRITICAL**: BDA service requires resource-based bucket policies to access S3. Lambda IAM permissions alone are NOT sufficient.

**Input Bucket Policy** (allow BDA to read files):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowBedrockDataAutomationRead",
            "Effect": "Allow",
            "Principal": {
                "Service": "bedrock.amazonaws.com"
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::input-bucket",
                "arn:aws:s3:::input-bucket/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "123456789012"
                }
            }
        }
    ]
}
```

**Processing Bucket Policy** (allow BDA to write results):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowBedrockDataAutomationWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "bedrock.amazonaws.com"
            },
            "Action": [
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::processing-bucket",
                "arn:aws:s3:::processing-bucket/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "123456789012"
                }
            }
        }
    ]
}
```

**Why Both Are Required**:
- **Lambda IAM Role**: Allows Lambda to invoke BDA API and read/write S3 for metadata
- **S3 Bucket Policies**: Allow BDA service itself to access buckets for document processing
- Without bucket policies: `AccessDeniedException: Access Denied. Check S3 URIs and read/write permissions`

**Multi-Region Profile Requirement**:
- BDA service uses AWS-managed default profiles: `us.data-automation-v1`
- Profiles exist in multiple regions: `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`
- BDA may route to different region profiles for load balancing/availability
- Lambda in `us-east-1` can trigger BDA operations using `us-east-2` profile
- **Always grant access to all BDA regions** to avoid AccessDenied errors

## Error Handling Considerations

1. **Throttling**: Implement exponential backoff for API calls
2. **Service Limits**: Monitor project creation limits per account
3. **File Formats**: Validate supported formats before invocation
4. **S3 Permissions**: Ensure BDA service role has access to S3 buckets
5. **Async Nature**: Design for eventual consistency and polling

## Next Steps

1. Configure BDA project with required extraction settings
2. Set up S3 buckets with appropriate permissions
3. Implement Lambda functions for invocation and status checking
4. Configure EventBridge rules for completion notifications
5. Add error handling and retry logic
6. Implement monitoring with CloudWatch metrics