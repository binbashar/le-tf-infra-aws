# KYB Agent Implementation Tasks

## Task Overview

This document outlines the implementation tasks for the KYB Agent layer following spec-driven development methodology. Each task references specific requirements and includes concrete implementation steps.

## [x] T-001: Layer Infrastructure Setup
**Requirements**: All use cases
**Dependencies**: None
**Purpose**: Create the basic layer structure and configuration files

### Subtasks:
- T-001.1: Create layer directory `data-science/us-east-1/bedrock-agent-kyb`
- T-001.2: Create `config.tf` with providers (aws, awscc, archive)
- T-001.3: Create `variables.tf` with standard layer variables
- T-001.4: Create `locals.tf` with naming conventions and tags
- T-001.5: Create `outputs.tf` with layer outputs structure
- T-001.6: Create `common-variables.tf` symlink

## [x] T-002: S3 Buckets Implementation
**Requirements**: REQ-001, REQ-003, REQ-004
**Dependencies**: T-001
**Purpose**: Create the three S3 buckets for the document pipeline

### Subtasks:
- T-002.1: Create `s3.tf` file
- T-002.2: Implement input bucket with EventBridge notifications
- T-002.3: Implement processing bucket with EventBridge notifications
- T-002.4: Implement output bucket with standard configurations
- T-002.5: Add bucket policies and encryption settings
- T-002.6: Configure lifecycle management
- T-002.7: Add S3 bucket outputs to `outputs.tf`

## [ ] T-003: Bedrock Data Automation Setup
**Requirements**: REQ-002
**Dependencies**: T-002
**Purpose**: Create BDA project with standard output configuration

### Subtasks:
- T-003.1: Create `bedrock.tf` file
- T-003.2: Implement BDA project resource with standard output
- T-003.3: Configure BDA project without custom blueprint
- T-003.4: Set proper encryption and tagging
- T-003.5: Add BDA project outputs to `outputs.tf`

## [ ] T-004: EventBridge Rules Configuration
**Requirements**: REQ-001
**Dependencies**: T-002, T-005
**Purpose**: Create EventBridge rule for input bucket trigger

### Subtasks:
- T-004.1: Create `eventbridge.tf` file
- T-004.2: Implement input bucket → BDA Lambda rule
- T-004.3: Configure event targets and retry policies
- T-004.4: Add dead letter queue for failed events (optional)

## [ ] T-004-API: API Gateway Setup
**Requirements**: REQ-002
**Dependencies**: T-005
**Purpose**: Create API Gateway with IAM authentication for external agent invocation

### Subtasks:
- T-004-API.1: Create `api_gateway.tf` file
- T-004-API.2: Implement REST API resource
- T-004-API.3: Create POST /invoke-agent endpoint with `authorization = "AWS_IAM"`
- T-004-API.4: Configure Lambda integration with Agent Invoker
- T-004-API.5: Add request validation for customer_id parameter
- T-004-API.6: Configure CORS if needed
- T-004-API.7: Add API Gateway outputs (endpoint URL, execution ARN, test command)

## [ ] T-005: Lambda Functions Implementation
**Requirements**: REQ-001, REQ-002, REQ-003, REQ-004
**Dependencies**: T-001, T-003
**Purpose**: Create all Lambda functions for the pipeline

### Subtasks:
- T-005.1: Create `lambda.tf` file
- T-005.2: Create Lambda layer with shared utilities
- T-005.3: Implement BDA Invoker Lambda function
- T-005.4: Implement Agent Invoker Lambda function
- T-005.5: Package Lambda source code files
- T-005.6: Add Lambda function outputs to `outputs.tf`

## [ ] T-006: BDA Invoker Lambda Code
**Requirements**: REQ-001, REQ-002
**Dependencies**: T-005
**Purpose**: Implement Lambda that triggers BDA processing

### Subtasks:
- T-006.1: Create `src/lambda/bda_invoker.py`
- T-006.2: Handle S3 ObjectCreated events from EventBridge
- T-006.3: Extract customer_id from S3 object key prefix for BDA processing context
- T-006.4: Generate correlation ID for tracking
- T-006.5: Invoke BDA with standard output configuration
- T-006.6: Store processing metadata

## [ ] T-007: Agent Invoker Lambda Code
**Requirements**: REQ-002, REQ-003
**Dependencies**: T-005, T-009, T-004-API
**Purpose**: Implement Lambda that triggers Bedrock Agent via IAM-authenticated API Gateway

### Subtasks:
- T-007.1: Create `src/lambda/agent_invoker.py`
- T-007.2: Handle API Gateway proxy events (IAM context available)
- T-007.3: Extract customer_id from request body
- T-007.4: Validate customer_id parameter (not empty, valid format)
- T-007.5: Invoke Bedrock Agent with session parameters (customer_id, output_type="Standard")
- T-007.6: Return JSON response with status, session_id, and agent_id
- T-007.7: Log IAM principal ARN for audit trail (optional)

## [ ] T-008: GetDocuments Action Group
**Requirements**: REQ-003
**Dependencies**: T-005, T-009
**Purpose**: Implement action group to retrieve BDA output

### Subtasks:
- T-008.1: Create `schemas/get_documents.yaml` OpenAPI schema
- T-008.2: Create `src/lambda/get_documents_handler.py`
- T-008.3: Handle session parameters automatically
- T-008.4: Retrieve documents from processing bucket using customer_id prefix: `standard/{customer_id}/`
- T-008.5: List all objects under customer_id prefix in processing bucket
- T-008.6: Return structured JSON response

## [ ] T-009: Bedrock Agent Configuration
**Requirements**: REQ-003, REQ-004
**Dependencies**: T-003
**Purpose**: Create Bedrock Agent with action groups

### Subtasks:
- T-009.1: Add agent configuration to `bedrock.tf`
- T-009.2: Configure agent with session parameters support
- T-009.3: Create GetDocuments action group resource
- T-009.4: Create SaveDocument action group resource
- T-009.5: Set agent instructions for document bypass processing
- T-009.6: Add Bedrock Agent outputs to `outputs.tf`

## [ ] T-010: SaveDocument Action Group
**Requirements**: REQ-004
**Dependencies**: T-005, T-009
**Purpose**: Implement action group to save processed results

### Subtasks:
- T-010.1: Create `schemas/save_document.yaml` OpenAPI schema
- T-010.2: Create `src/lambda/save_document_handler.py`
- T-010.3: Handle session parameters automatically
- T-010.4: Save results to output bucket
- T-010.5: Maintain correlation ID in metadata

## [ ] T-011: IAM Permissions Setup
**Requirements**: All use cases
**Dependencies**: T-002, T-003, T-005, T-009
**Purpose**: Configure IAM roles and policies

### Subtasks:
- T-011.1: Create `iam.tf` file
- T-011.2: Create Lambda execution roles (Agent Invoker, BDA Invoker, Action Groups)
- T-011.3: Create BDA service permissions
- T-011.4: Create Bedrock Agent service role with action group invocation
- T-011.5: Create S3 bucket access policies for Lambdas
- T-011.6: Create API Gateway invocation permissions for Agent Invoker Lambda
- T-011.7: Create EventBridge invocation permissions for BDA Invoker Lambda
- T-011.8: Add Bedrock InvokeAgent permission to Agent Invoker role
- T-011.9: Add IAM role outputs to `outputs.tf`
- T-011.10: Note: API Gateway uses default same-account access (no explicit resource policy needed)

## [ ] T-012: Deployment and Verification
**Requirements**: All use cases
**Dependencies**: All previous tasks
**Purpose**: Deploy and verify the complete pipeline

### Subtasks:
- T-012.1: Run `leverage tf init` in layer directory
- T-012.2: Run `leverage tf plan` and review
- T-012.3: Run `leverage tf apply` to deploy
- T-012.4: Upload test PDF to input bucket
- T-012.5: Verify end-to-end document processing pipeline

## Implementation Order

1. **Phase 1**: Infrastructure (T-001, T-002, T-003)
2. **Phase 2**: Event Processing (T-004, T-004-API, T-005)
3. **Phase 3**: Lambda Implementation (T-006, T-007)
4. **Phase 4**: Agent Configuration (T-008, T-009, T-010)
5. **Phase 5**: Security and Deployment (T-011, T-012)

## Success Criteria

- [ ] PDF upload triggers BDA processing
- [ ] BDA saves standard output to processing bucket with customer_id prefix
- [ ] API Gateway endpoint requires IAM authentication (SigV4 signing)
- [ ] API Gateway endpoint accepts customer_id and triggers agent invocation
- [ ] IAM-authenticated requests successfully invoke the API
- [ ] Agent Invoker receives customer_id and passes as session parameter
- [ ] Agent retrieves documents using GetDocuments with customer_id prefix
- [ ] GetDocuments uses customer_id to locate customer-specific documents in processing bucket
- [ ] Agent saves bypass results using SaveDocument
- [ ] All resources deployed successfully via Leverage CLI
- [ ] Test command works with deployer's AWS credentials (awscurl)