# T-004: EventBridge Rules Configuration - Detailed Plan

## Overview
Implement EventBridge rule to trigger BDA Invoker Lambda when PDFs are uploaded to the input bucket. Follows minimal implementation principles (DRY, KISS, YAGNI).

## Execution Strategy
Execute subtasks **sequentially** in the order listed below. Each subtask must complete and validate before moving to the next.

---

## Prerequisites Verification

**Already Completed** (from T-002):
- ✅ S3 input bucket has EventBridge notifications enabled (`aws_s3_bucket_notification.input.eventbridge = true`)
- ✅ S3 processing bucket has EventBridge notifications enabled (`aws_s3_bucket_notification.processing.eventbridge = true`)

**Already Completed** (from T-005):
- ✅ BDA Invoker Lambda function created (`aws_lambda_function.bda_invoker`)
- ✅ Lambda IAM role configured (`aws_iam_role.bda_invoker_role`)

**Ready to Implement**:
- EventBridge rule to capture S3 ObjectCreated events
- EventBridge target to invoke BDA Invoker Lambda
- Lambda permission for EventBridge invocation
- Retry policy for failed invocations

---

## Subtask Breakdown

### T-004.1: Create `eventbridge.tf` file

**Purpose**: Create new file for EventBridge infrastructure

**Actions**:
1. Create file: `eventbridge.tf`
2. Add file header comment (minimal - one line explaining purpose)

**Pattern Reference**: `/data-science/us-east-1/bedrock-kyb-bda/eventbridge.tf`

**Validation**: File created in layer directory

---

### T-004.2: Implement input bucket → BDA Lambda rule

**Purpose**: Create EventBridge rule to detect S3 ObjectCreated events in input bucket

**Actions**:
1. Add `aws_cloudwatch_event_rule` resource to `eventbridge.tf`:

```hcl
resource "aws_cloudwatch_event_rule" "input_bucket_trigger" {
  name        = local.input_rule_name
  description = "Trigger BDA processing when PDFs are uploaded to input bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.input.bucket]
      }
      object = {
        key = [{
          "suffix" = ".pdf"
        }]
      }
    }
  })

  tags = local.tags
}
```

**Pattern Reference**: bedrock-kyb-bda EventBridge rule pattern

**Key Configuration**:
- **Event Pattern**: Matches S3 ObjectCreated events
- **Bucket Filter**: Only input bucket events
- **File Filter**: Only `.pdf` files (suffix filter)
- **Name**: Uses `local.input_rule_name` from locals.tf (already defined)
- **Tags**: Standard layer tags

**Alternative Consideration**:
- Could filter by prefix pattern `{customer_id}/*` but not necessary for MVP
- Suffix filter `.pdf` ensures only PDF files trigger processing
- Lambda can validate full S3 key structure if needed

**Validation**: Rule resource defined with proper event pattern

---

### T-004.3: Configure event targets and retry policies

**Purpose**: Configure EventBridge to invoke BDA Invoker Lambda with retry logic

**Actions**:
1. Add `aws_cloudwatch_event_target` resource to `eventbridge.tf`:

```hcl
resource "aws_cloudwatch_event_target" "bda_invoker_target" {
  rule      = aws_cloudwatch_event_rule.input_bucket_trigger.name
  target_id = "BDAInvokerTarget"
  arn       = aws_lambda_function.bda_invoker.arn

  retry_policy {
    maximum_retry_attempts       = 2
    maximum_event_age_in_seconds = 3600
  }
}
```

**Pattern Reference**: bedrock-kyb-bda target configuration

**Key Configuration**:
- **Target ARN**: Points to BDA Invoker Lambda
- **Retry Policy**: 2 retry attempts (minimal but reasonable)
- **Max Event Age**: 1 hour (3600 seconds)
- **No DLQ**: Minimal implementation (DLQ is T-004.4 optional)

**Retry Policy Reasoning**:
- 2 retries = 3 total attempts (initial + 2 retries)
- 1 hour max age prevents infinite retry loops
- Sufficient for transient failures (throttling, temporary service issues)

**Validation**: Target resource defined with retry policy

---

### T-004.4: Add Lambda permission for EventBridge invocation

**Purpose**: Allow EventBridge to invoke BDA Invoker Lambda

**Actions**:
1. Add `aws_lambda_permission` resource to `eventbridge.tf`:

```hcl
resource "aws_lambda_permission" "allow_eventbridge_bda_invoker" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bda_invoker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.input_bucket_trigger.arn
}
```

**Pattern Reference**: Standard Lambda permission for EventBridge

**Key Configuration**:
- **Principal**: `events.amazonaws.com` (EventBridge service)
- **Source ARN**: Specific EventBridge rule (least privilege)
- **Action**: `lambda:InvokeFunction` only

**Security Note**: Source ARN constraint ensures only this specific EventBridge rule can invoke the Lambda

**Validation**: Permission resource defined

---

### T-004.5 (OPTIONAL): Add dead letter queue for failed events

**Purpose**: Capture events that fail after all retry attempts (optional for MVP)

**Status**: **SKIP FOR MINIMAL IMPLEMENTATION**

**Reasoning**:
- DLQ adds operational overhead (monitoring, queue management)
- Lambda has CloudWatch logs for debugging failed invocations
- Can add DLQ later if operational experience shows need
- Not required for REQ-001 (basic event-driven pipeline)

**If Implementing Later** (not part of this task):
1. Create SQS queue resource
2. Add SQS queue policy allowing EventBridge
3. Add `dead_letter_config` to target resource
4. Add outputs for DLQ URL and ARN

**Pattern Reference**: bedrock-kyb-bda has DLQ implementation if needed later

**Validation**: Skip this subtask for minimal implementation

---

### T-004.6: Add EventBridge outputs to `outputs.tf`

**Purpose**: Expose EventBridge rule information for verification and monitoring

**Actions**:
1. Add to `outputs.tf`:

```hcl
output "input_trigger_rule_name" {
  description = "Name of the EventBridge rule for input bucket trigger"
  value       = aws_cloudwatch_event_rule.input_bucket_trigger.name
}

output "input_trigger_rule_arn" {
  description = "ARN of the EventBridge rule for input bucket trigger"
  value       = aws_cloudwatch_event_rule.input_bucket_trigger.arn
}
```

**Pattern Reference**: Standard outputs pattern from outputs.tf

**Outputs Exposed**:
- Rule name (for AWS CLI operations)
- Rule ARN (for IAM policies, monitoring)

**Validation**: 2 new outputs defined

---

### T-004.7: Run validation and formatting

**Purpose**: Ensure Terraform configuration is valid and properly formatted

**Actions**:
1. Navigate to layer directory: `cd data-science/us-east-1/bedrock-agent-kyb`
2. Run `leverage tf validate` - must pass
3. Run `leverage tf format` - format all files
4. Verify no validation errors
5. Review plan for expected resources

**Expected Resources**:
- 1 EventBridge rule (create)
- 1 EventBridge target (create)
- 1 Lambda permission (create)
- Total: 3 new resources

**Validation**: `leverage tf validate` returns "Success! The configuration is valid."

---

### T-004.8: Deploy EventBridge infrastructure

**Purpose**: Deploy EventBridge rule and target to AWS

**Actions**:
1. Run `leverage tf plan` and review:
   - 1 EventBridge rule to create
   - 1 EventBridge target to create
   - 1 Lambda permission to create
   - Total: 3 resources

2. Run `leverage tf apply` to deploy

3. Verify outputs:
   - Rule name present
   - Rule ARN correct

4. Verify rule in AWS Console:
   - Rule status should be "Enabled"
   - Event pattern should match input bucket
   - Target should point to BDA Invoker Lambda

**Testing After Deployment**:
1. Upload test PDF to input bucket: `aws s3 cp test.pdf s3://{input-bucket}/test-customer-123/document.pdf`
2. Check EventBridge rule metrics in CloudWatch
3. Check Lambda invocation in CloudWatch Logs
4. Verify BDA Invoker Lambda received S3 event

**Expected Results**:
- EventBridge rule created and enabled
- Target configured with retry policy
- Lambda permission granted
- Test upload triggers Lambda invocation

**Validation**:
- `leverage tf output` shows 2 EventBridge outputs
- AWS Console shows rule in "Enabled" state
- Test upload successfully triggers Lambda

---

## Implementation Notes

### EventBridge Event Pattern

The event pattern for S3 ObjectCreated events via EventBridge:

```json
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["bucket-name"]
    },
    "object": {
      "key": [{"suffix": ".pdf"}]
    }
  }
}
```

**Key Fields**:
- `source`: Always "aws.s3" for S3 events
- `detail-type`: "Object Created" for s3:ObjectCreated:* events
- `detail.bucket.name`: Filter by specific bucket
- `detail.object.key`: Optional filters (prefix, suffix)

### Lambda Event Structure

BDA Invoker Lambda receives this event format:

```json
{
  "version": "0",
  "id": "event-id",
  "detail-type": "Object Created",
  "source": "aws.s3",
  "time": "2025-10-06T12:00:00Z",
  "region": "us-east-1",
  "resources": ["arn:aws:s3:::bucket-name"],
  "detail": {
    "version": "0",
    "bucket": {
      "name": "bucket-name"
    },
    "object": {
      "key": "customer-123/document.pdf",
      "size": 12345,
      "etag": "etag-value"
    },
    "request-id": "request-id",
    "requester": "aws-account-id"
  }
}
```

**Important Fields for Lambda**:
- `detail.bucket.name`: Source bucket
- `detail.object.key`: S3 object key (includes customer_id prefix)
- `detail.object.size`: File size in bytes

### Retry Policy Behavior

**Retry Configuration**:
- **Initial Attempt**: Immediate invocation when event arrives
- **Retry 1**: After exponential backoff (~1 second)
- **Retry 2**: After exponential backoff (~2 seconds)
- **Max Event Age**: 1 hour - events older than this are dropped

**Failure Scenarios**:
- Lambda timeout: Event retried
- Lambda error (unhandled exception): Event retried
- Lambda throttling: Event retried with backoff
- After 2 retries: Event dropped (no DLQ in minimal implementation)

**CloudWatch Logs**: All attempts logged in Lambda CloudWatch Logs for debugging

### S3 EventBridge Integration

**How It Works**:
1. S3 bucket has `eventbridge = true` notification enabled
2. S3 sends ObjectCreated events to EventBridge
3. EventBridge matches events against rules
4. Matching events invoke configured targets (Lambda)

**Event Delivery**:
- **At-least-once**: Events may be delivered multiple times (Lambda should be idempotent)
- **Near real-time**: Typically within seconds of object creation
- **No ordering guarantee**: Multiple uploads may process out of order

### Testing Event Flow

**Manual Test**:
```bash
# Upload test PDF with customer_id prefix
aws s3 cp test-document.pdf s3://bb-data-science-kyb-agent-input-05fb92/test-customer-123/document.pdf

# Check EventBridge rule metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name Invocations \
  --dimensions Name=RuleName,Value=bb-data-science-kyb-agent-input-trigger \
  --start-time 2025-10-06T00:00:00Z \
  --end-time 2025-10-06T23:59:59Z \
  --period 300 \
  --statistics Sum

# Check Lambda logs
aws logs tail /aws/lambda/bb-data-science-kyb-agent-bda-invoker --follow
```

**Expected Flow**:
1. PDF uploaded to S3 input bucket
2. S3 sends ObjectCreated event to EventBridge
3. EventBridge matches event pattern
4. EventBridge invokes BDA Invoker Lambda
5. Lambda logs event to CloudWatch
6. Lambda invokes BDA (business logic in T-006)

---

## File Summary

**New Files Created** (1 total):
1. `eventbridge.tf` (~50 lines) - EventBridge rule, target, Lambda permission

**Modified Files** (1 total):
1. `outputs.tf` (~10 lines added) - EventBridge outputs

**Total New Lines**: ~60 lines across all files

---

## Success Criteria

- ✅ `eventbridge.tf` file created with 3 resources
- ✅ EventBridge rule matches S3 ObjectCreated events for `.pdf` files
- ✅ Target configured with retry policy (2 attempts, 1 hour max age)
- ✅ Lambda permission allows EventBridge invocation
- ✅ Outputs defined for rule name and ARN
- ✅ Terraform validation passes
- ✅ Infrastructure deployed successfully
- ✅ Test PDF upload triggers Lambda invocation
- ✅ CloudWatch logs show event received by Lambda
- ✅ Code follows minimal implementation principles (no DLQ)
- ✅ T-004 marked complete in tasks.md

---

## Next Steps After T-004

After completing T-004, the following tasks can proceed:
- **T-006**: BDA Invoker Lambda Code (depends on T-005, T-004) - **Ready** ✅
- **T-004-API**: API Gateway Setup (depends on T-005) - No T-004 dependency
- **T-007**: Agent Invoker Lambda Code (depends on T-005, T-009, T-004-API)

**Recommended Next**: T-006 BDA Invoker Lambda Code - implements business logic to trigger BDA processing when EventBridge rule fires

---

## Architecture Diagram

```
┌─────────────────┐
│  Input Bucket   │
│  (S3)           │
│  - EventBridge  │
│    enabled      │
└────────┬────────┘
         │ ObjectCreated
         │ event (.pdf)
         ▼
┌─────────────────┐
│  EventBridge    │
│  Rule           │
│  - Filter: pdf  │
│  - Retry: 2x    │
└────────┬────────┘
         │ invoke
         ▼
┌─────────────────┐
│  BDA Invoker    │
│  Lambda         │
│  - Process      │
│    event        │
│  - Invoke BDA   │
└─────────────────┘
```

**Data Flow**:
1. User uploads PDF to input bucket with customer_id prefix
2. S3 sends ObjectCreated event to EventBridge
3. EventBridge rule matches event (source=aws.s3, suffix=.pdf, bucket=input)
4. EventBridge invokes BDA Invoker Lambda with event payload
5. Lambda receives event with S3 bucket name and object key
6. Lambda extracts customer_id from object key prefix
7. Lambda invokes BDA (business logic in T-006)

---

## References

- [EventBridge Event Pattern for S3](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)
- [S3 EventBridge Integration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventBridge.html)
- [Lambda Retry Behavior](https://docs.aws.amazon.com/lambda/latest/dg/invocation-retries.html)
- [EventBridge Rule Pattern Reference](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns-content-based-filtering.html)
