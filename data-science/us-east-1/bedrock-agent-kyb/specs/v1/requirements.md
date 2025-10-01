# KYB Agent Requirements

## Use Cases

**WHEN** the user saves PDF files in an input bucket
**THEN** the system SHALL start an EventBridge trigger that invokes a lambda to start BDA processing

**WHEN** an IAM-authenticated system invokes the API Gateway with a customer_id
**THEN** the system SHALL invoke a lambda that triggers the Bedrock Agent with the customer_id as a session parameter

**WHEN** the Bedrock Agent is invoked with session parameters
**THEN** the agent SHALL use a GetDocuments action group (lambda) to retrieve processed documents from the processing bucket using standard output folder structure

**WHEN** the agent retrieves documents
**THEN** the agent SHALL use a SaveDocument action group (lambda) to save the extraction (bypass) in the output bucket

**WHEN** the user uploads PDFs with customer-specific prefixes to the input bucket
**THEN** BDA SHALL maintain the customer_id prefix structure in the processing bucket standard output

## Technical Notes

- BDA will use **standard output** (not custom blueprint) for document extraction
- Standard output saves OCR extraction in a different folder structure than custom output
- Agent uses **session parameters** to automatically inject parameters to action groups
- GetDocuments action group receives `output_type` parameter set to "Standard"
- Session parameters avoid the need for explicit parameter passing between agent and action groups
- Input bucket SHALL organize files by customer_id prefix: `{customer_id}/document.pdf`
- BDA standard output SHALL preserve customer_id prefix in processing bucket structure
- API Gateway endpoint SHALL require AWS IAM authentication (SigV4 request signing)
- API Gateway endpoint SHALL accept customer_id parameter in request body
- By default, any IAM principal in the same AWS account can invoke the API
- Agent Invoker Lambda SHALL pass customer_id as session parameter to Bedrock Agent
- GetDocuments action group SHALL use customer_id as S3 prefix to locate documents in processing bucket

## Non-Functional Requirement: Minimal Implementation

This implementation SHALL follow a **minimal, concise approach**.