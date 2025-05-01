# Document Processing Lambda Functions

This directory contains Lambda functions for document processing and KYB (Know Your Business) workflows. The implementation leverages the AWS Bedrock Data Automation CDK construct for standardized blueprint management and processing.

## KYB Workflow Overview

The KYB process follows these steps:

1. **Document Upload**: Documents are uploaded to the S3 input bucket under the `kyb/` prefix
2. **Document Type Detection**: The system automatically detects the document type (EIN, Form 1120, Company Formation, Actionary Composition, or Passport)
3. **Blueprint Selection**: Based on the document type, the appropriate blueprint is selected for processing
4. **Document Processing**: The document is processed using AWS Bedrock Data Automation
5. **Validation**: The processed results are validated against specific rules for each document type
6. **Status Update**: The document status is updated in DynamoDB

## Lambda Functions

### 1. Document Processing Lambda (`processing/`)
- Handles the core document processing using AWS Bedrock Data Automation
- Features:
  - Automatic document type detection
  - Blueprint selection and validation
  - Integration with Bedrock Data Automation
  - Status tracking in DynamoDB
  - Error handling and retries

### 2. Document Validation Lambda (`validation/`)
- Validates processed documents against specific rules
- Features:
  - Field-level validation (required fields, email format, dates)
  - Custom validation rules per document type
  - Validation result tracking
  - Error handling and status updates

### 3. Document Splitter Lambda (`document_splitter/`)
- Handles multi-page document processing
- Features:
  - Page extraction and splitting
  - Metadata management
  - Parallel processing support

### 4. Blueprint Creation Lambda (`blueprint_creation/`)
- Manages KYB document blueprints
- Features:
  - Blueprint definition for each document type
  - Field extraction rules
  - Validation rule management

## Supported Document Types

The KYB solution supports the following document types with specific validation rules:

1. **Passport**
   - Required fields: fullName, passportNumber, nationality, dateOfBirth, expiryDate
   - Format validation: passport number (6-9 alphanumeric characters), expiry date (YYYY-MM-DD)

2. **EIN Verification**
   - Required fields: einNumber, businessName, issueDate
   - Format validation: EIN number format, date validation

3. **Form 1120 Income Tax**
   - Required fields: businessName, taxYear, totalIncome, totalDeductions
   - Format validation: monetary values, date validation

4. **Company Formation**
   - Required fields: companyName, formationDate, registeredAgent, businessType
   - Format validation: date validation, business type enumeration

5. **Actionary Composition**
   - Required fields: companyName, shareholders, shareDistribution, date
   - Format validation: percentage values, date validation

## Event-based Processing

Document processing can be triggered via:

1. **S3 Event Notifications**: Automatic processing when documents are uploaded to the `kyb/` prefix
2. **Step Functions Workflow**: Orchestrated processing with error handling and retries
3. **Direct API Invocation**: Manual processing through the Bedrock Agent
4. **EventBridge Events**: Custom workflow integration

## Error Handling and Monitoring

- Each Lambda function includes comprehensive error handling
- Status tracking in DynamoDB for each processing step
- CloudWatch logging and metrics
- Retry mechanisms for transient failures
- Validation error reporting and tracking

## References

For more information on the AWS Bedrock Data Automation construct, see [the official documentation](https://github.com/awslabs/generative-ai-cdk-constructs/tree/v0.1.300/src/patterns/gen-ai/aws-bedrock-data-automation). 