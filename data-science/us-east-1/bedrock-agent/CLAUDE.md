# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layer Overview

This is the **AWS Bedrock Agent layer** within the Binbash Leverage Reference Architecture, located at `data-science/us-east-1/bedrock-agent`. It implements a simplified Bedrock Agent with S3 integration capabilities using Lambda functions and structured logging.

## Essential Commands

### Infrastructure Deployment
```bash
# Navigate to the layer directory (REQUIRED)
cd data-science/us-east-1/bedrock-agent

# Initialize and validate
leverage tf init
leverage tf validate
leverage tf format  # Format all Terraform files

# Plan and review changes
leverage tf plan

# Apply infrastructure
leverage tf apply

# Destroy infrastructure (when needed)
leverage tf destroy
```

### Lambda Development Workflow
```bash
# After modifying Lambda code or layer dependencies:
leverage tf plan -target=aws_lambda_layer_version.bedrock_agent_utils -target=aws_lambda_function.s3_read -target=aws_lambda_function.s3_write

# Apply Lambda changes only
leverage tf apply -target=aws_lambda_layer_version.bedrock_agent_utils -target=aws_lambda_function.s3_read -target=aws_lambda_function.s3_write -auto-approve
```

### Monitoring and Debugging
```bash
# Test agent preparation
aws bedrock-agent prepare-agent --agent-id ${AGENT_ID} --region us-east-1 --profile bb-data-science-devops

# View Lambda logs
aws logs tail /aws/lambda/bb-data-science-agent-s3-read --follow
aws logs tail /aws/lambda/bb-data-science-agent-s3-write --follow

# Query structured logs with CloudWatch Insights
aws logs start-query --log-group-name /aws/lambda/bb-data-science-agent-s3-read \
  --start-time $(date -u -d '1 hour ago' '+%s') \
  --end-time $(date '+%s') \
  --query-string 'fields @timestamp, correlation_id, event, bucket, key | filter event = "s3_read_initiated"'
```

## Architecture and Key Design Decisions

### Component Structure
The layer follows a **simplified, fast-deployment architecture**:

1. **Terraform Configuration** (`*.tf` files):
   - `main.tf`: Bedrock agent module instantiation (uses aws-ia/bedrock/aws module v0.0.29)
   - `lambda.tf`: Lambda functions and layer definitions
   - `iam.tf`: IAM roles and policies
   - `s3.tf`: S3 buckets for documents and schemas
   - Uses Claude 3 Haiku model for cost efficiency (configurable via `agent_foundation_model`)

2. **Lambda Layer** (`src/layers/bedrock_agent/`):
   - `requirements.txt`: Contains `structlog==25.4.0` for structured logging
   - `python/bedrock_agent_utils.py`: Shared utilities with structured logging configuration
   - Automatically packaged as zip and deployed as Lambda layer

3. **Lambda Functions** (`src/lambda/`):
   - `s3_read_handler.py`: Handles S3 read operations with correlation ID tracking
   - `s3_write_handler.py`: Handles S3 write operations with structured logging
   - Both use the shared layer for utilities and logging

### Structured Logging Implementation
The layer implements **professional structured logging** with minimal overhead:
- **Correlation IDs**: Every request gets a unique UUID for end-to-end tracing
- **JSON format**: CloudWatch Insights compatible structured logs
- **Dynamic log levels**: Controlled via `LOG_LEVEL` environment variable
- **Event-based logging**: Specific events like `s3_read_initiated`, `s3_operation_failed`

### Module Dependencies and Constraints
- **Parent Module**: Uses `aws-ia/bedrock/aws` module which brings in `awscc` and `opensearch` providers
- **Knowledge Base**: Disabled (`create_kb = false`) to reduce complexity
- **Encryption**: Disabled by default (`enable_encryption = false`) for faster deployment

### State Management
- Backend: S3 with key `data-science/us-east-1/bedrock-agent/terraform.tfstate`
- Remote state dependencies:
  - `security-keys`: For KMS encryption (when enabled)
  - `vpc`: For network configuration (if needed)

## Critical Implementation Details

### Lambda Layer Building
The `data.archive_file.bedrock_agent_layer` resource automatically:
1. Packages the entire `src/layers/bedrock_agent` directory
2. Includes Python dependencies from `requirements.txt`
3. Creates a zip file for deployment
4. Triggers layer recreation when contents change

### Lambda Function Deployment
- Runtime: Python 3.13
- Memory: 512MB (configurable via `lambda_memory_size`)
- Timeout: 60 seconds (configurable via `lambda_timeout`)
- Environment variables:
  - `DOCUMENTS_BUCKET`: Dynamically set to the created S3 bucket
  - `LOG_LEVEL`: Controls logging verbosity (INFO/DEBUG/WARNING/ERROR)

### IAM Permission Model
- **Agent Service Role**: Allows Bedrock to invoke foundation models and Lambda functions
- **Lambda Execution Role**: Grants S3 access to specific buckets only
- **Resource-based Policies**: Lambda functions have explicit permissions for Bedrock invocation

### S3 Bucket Configuration
- **Public Access**: Blocked on all buckets
- **Versioning**: Enabled for document recovery
- **Lifecycle**: 90-day transition to Infrequent Access storage class
- **Encryption**: Optional KMS encryption (disabled by default)

## Development Patterns

### Adding New Lambda Functions
1. Create handler in `src/lambda/new_handler.py`
2. Import utilities: `from bedrock_agent_utils import parse_request, format_response, get_structured_logger`
3. Add correlation ID logging: `logger = get_structured_logger(request["correlation_id"])`
4. Define Lambda resource in `lambda.tf`
5. Add Lambda permission for Bedrock in `lambda.tf`
6. Update outputs in `outputs.tf`

### Modifying the Lambda Layer
1. Update `src/layers/bedrock_agent/requirements.txt` for new dependencies
2. Modify `src/layers/bedrock_agent/python/bedrock_agent_utils.py` for shared utilities
3. Run targeted apply: `leverage tf apply -target=aws_lambda_layer_version.bedrock_agent_utils`

### Testing Structured Logging
CloudWatch Insights queries for debugging:
```sql
-- Trace request by correlation ID
fields @timestamp, level, event, bucket, key, error
| filter correlation_id = "YOUR-ID"
| sort @timestamp asc

-- Monitor S3 operations
fields @timestamp, operation, bucket, key, content_size
| filter event like /s3_.*_completed/
| stats count() by operation

-- Error analysis
fields @timestamp, correlation_id, error_type, error
| filter level = "error"
| stats count() by error_type
```

## Known Issues and Workarounds

### Provider Configuration
The module brings in `awscc` and `opensearch` providers that aren't used. If you encounter provider errors during `terraform plan`:
```bash
rm -rf .terraform .terraform.lock.hcl
leverage tf init
```

### Agent Preparation
The agent must be prepared after creation. This is handled by `null_resource.prepare_agent` but may fail if AWS CLI isn't configured. Manual preparation:
```bash
aws bedrock-agent prepare-agent --agent-id $(leverage tf output -raw agent_id) --region us-east-1 --profile bb-data-science-devops
```

### Lambda Cold Starts
First invocations may timeout. Consider:
- Increasing `lambda_timeout` variable
- Implementing Lambda warmup strategies
- Using provisioned concurrency for production

## Integration Points

### Outputs for Other Layers
- `agent_id`, `agent_arn`: For invoking the agent from other services
- `documents_bucket_name`: For cross-layer S3 access
- `s3_read_lambda_arn`, `s3_write_lambda_arn`: For direct Lambda invocation
- `bedrock_agent_layer_arn`: For sharing the utilities layer

### Remote State Usage
Access outputs from other layers:
```hcl
data.terraform_remote_state.bedrock_agent {
  backend = "s3"
  config = {
    bucket = var.bucket
    key    = "data-science/us-east-1/bedrock-agent/terraform.tfstate"
    region = var.region
  }
}

# Use: data.terraform_remote_state.bedrock_agent.outputs.agent_id
```