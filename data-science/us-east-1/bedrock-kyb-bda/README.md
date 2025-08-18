# Bedrock KYB Agent - Know Your Business Data Automation

This OpenTofu configuration deploys a comprehensive Know Your Business (KYB) data automation solution using AWS Bedrock Data Automation. The system automatically processes business documents uploaded to an S3 bucket and extracts structured compliance data.

## Architecture Overview

The KYB agent consists of the following components:

1. **S3 Buckets**: Input and output buckets for document processing
2. **Bedrock Data Automation Project**: Processes documents using AI/ML models
3. **Custom Blueprint**: Defines the KYB data extraction schema
4. **Lambda Function**: Orchestrates the BDA processing workflow
5. **EventBridge Rule**: Triggers processing when documents are uploaded
6. **IAM Roles**: Secure access between services
7. **Dead Letter Queue**: Handles failed processing attempts

## Document Processing Flow

1. Business documents are uploaded to the input S3 bucket
2. S3 sends an event to EventBridge when objects are created
3. EventBridge triggers the Lambda function
4. Lambda invokes Bedrock Data Automation asynchronously
5. BDA processes the document using the custom KYB blueprint
6. Extracted data is saved to the output S3 bucket in JSON format
7. Processing metadata is stored for audit trails

## Supported Document Types

The system can process various business document formats:

- PDF documents (articles of incorporation, business licenses)
- Image files (PNG, JPEG, TIFF) of scanned documents
- Microsoft Word documents (DOC, DOCX)

## KYB Data Extraction Schema

The custom blueprint extracts the following business information:

### Core Business Information
- Official business name
- Registration/incorporation number  
- Tax identification number (EIN, VAT, etc.)
- Date of incorporation
- Business type (LLC, Corporation, Partnership, etc.)
- Primary industry or sector

### Address Information
- Complete registered business address
- Street, city, state/region, postal code, and country

### Corporate Structure
- Directors and their positions
- Key shareholders and ownership percentages
- Management team members

### Compliance Status
- Sanctions screening results
- PEP (Politically Exposed Person) status
- Adverse media findings
- Regulatory compliance status

## Deployment Instructions

### Prerequisites

1. Ensure you have the correct AWS credentials configured
2. Initialize the OpenTofu backend configuration
3. Verify that the `security-keys` layer has been deployed for KMS encryption

### Deploy the Infrastructure

```bash
# Navigate to the layer directory
cd data-science/us-east-1/bedrock-kyb-agent

# Initialize OpenTofu
leverage tofu init

# Plan the deployment
leverage tofu plan

# Apply the configuration
leverage tofu apply
```

### Configuration Variables

The following variables can be customized:

- `kyb_extraction_schema`: JSON schema defining data extraction structure
- `enable_encryption`: Enable KMS encryption (default: true)
- `lambda_timeout`: Lambda function timeout in seconds (default: 300)
- `lambda_memory_size`: Lambda function memory in MB (default: 1024)
- `s3_lifecycle_days`: Days before transitioning to STANDARD_IA (default: 90)
- `s3_glacier_days`: Days before transitioning to GLACIER (default: 365)
- `enable_s3_versioning`: Enable S3 bucket versioning (default: true)

## Usage Instructions

### Upload Documents for Processing

1. Upload business documents to the input S3 bucket:
   ```bash
   aws s3 cp business-document.pdf s3://[input-bucket-name]/
   ```

2. Monitor processing through CloudWatch logs:
   ```bash
   aws logs tail /aws/lambda/[lambda-function-name] --follow
   ```

### Retrieve Processed Data

1. Check the output S3 bucket for extracted data:
   ```bash
   aws s3 ls s3://[output-bucket-name]/processed/
   ```

2. Download the JSON results:
   ```bash
   aws s3 cp s3://[output-bucket-name]/processed/document_timestamp.json ./
   ```

### Monitor Processing Status

1. Check processing metadata:
   ```bash
   aws s3 ls s3://[output-bucket-name]/metadata/
   ```

2. View failed processing attempts in the dead letter queue:
   ```bash
   aws sqs receive-message --queue-url [dlq-url]
   ```

## Output Format

The system outputs structured JSON data following this format:

```json
{
  "business_name": "Example Business LLC",
  "registration_number": "LLC123456789",
  "tax_id": "12-3456789",
  "date_of_incorporation": "2020-01-15",
  "registered_address": {
    "street": "123 Business St",
    "city": "Business City",
    "state": "BC",
    "postal_code": "12345",
    "country": "USA"
  },
  "business_type": "Limited Liability Company",
  "industry": "Professional Services",
  "directors": [
    {
      "name": "John Doe",
      "position": "Managing Director",
      "appointment_date": "2020-01-15"
    }
  ],
  "shareholders": [
    {
      "name": "John Doe",
      "ownership_percentage": 100
    }
  ],
  "compliance_status": {
    "sanctions_check": true,
    "pep_check": false,
    "adverse_media": false
  }
}
```

## Security Features

- **Encryption**: All data is encrypted at rest using KMS
- **Access Control**: IAM roles follow principle of least privilege
- **Secure Transport**: All S3 operations require HTTPS
- **Network Security**: VPC endpoints can be configured for private communication
- **Audit Trail**: Processing metadata and logs for compliance tracking

## Monitoring and Troubleshooting

### CloudWatch Metrics

Monitor the following metrics:
- Lambda function invocations and errors
- S3 bucket request metrics
- DLQ message count

### Common Issues

1. **Processing Failures**: Check the dead letter queue for failed messages
2. **Permission Errors**: Verify IAM roles have required permissions
3. **Document Format**: Ensure documents are in supported formats
4. **Schema Validation**: Verify extracted data matches the JSON schema

### Logs

- Lambda function logs: `/aws/lambda/[function-name]`
- Bedrock Data Automation logs: Available through AWS CloudTrail

## Cost Optimization

- S3 lifecycle policies automatically transition old files to cheaper storage
- Lambda functions are configured with appropriate memory and timeout settings
- Dead letter queue prevents infinite retry costs
- KMS encryption uses AWS managed keys by default

## Compliance and Governance

- All resources are tagged for cost allocation and governance
- Processing metadata provides audit trails
- Data retention policies follow organizational requirements
- Access logging available for compliance reporting

## Future Enhancements

- Integration with compliance databases for sanctions screening
- Real-time processing notifications via SNS
- Advanced document classification and routing
- Integration with business identity verification services
- Multi-language document processing support