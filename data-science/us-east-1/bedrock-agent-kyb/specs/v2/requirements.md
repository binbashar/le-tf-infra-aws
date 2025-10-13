# KYB Agent Requirements v2

## Use Cases

**WHEN** the user saves PDF files in an input bucket
**THEN** the system SHALL start an EventBridge trigger that invokes a lambda to start BDA processing

**WHEN** an IAM-authenticated system invokes the API Gateway with a customer_id
**THEN** the system SHALL invoke a lambda that triggers the Bedrock Agent with the customer_id as a session parameter

**WHEN** the Bedrock Agent is invoked with session parameters
**THEN** the agent SHALL use a GetDocuments action group (lambda) to retrieve processed documents from the processing bucket using both custom output and standard output folder structures, providing the agent with both data types simultaneously

**WHEN** the agent needs to verify if a person is politically exposed or has sanctions
**THEN** the agent SHALL use a CheckSanctions action group (lambda) to check sanctions status with person name/surname or document ID

**WHEN** the CheckSanctions action group receives a request
**THEN** it SHALL return mocked sanctions data (demo mode) with num_sanctions and pep_score

**WHEN** the agent receives sanctions results indicating any sanctions (num_sanctions > 0) or high PEP score
**THEN** the agent SHALL set the KYB verdict as REJECTED and include sanctions information in the verdict

**WHEN** the agent cannot identify company representatives in the processed documents
**THEN** the agent SHALL set the KYB verdict as REVIEW_REQUIRED with a note explaining missing representative information

**WHEN** the agent verifies all company representatives have no sanctions and acceptable PEP scores
**THEN** the agent SHALL set the KYB verdict as APPROVED

**WHEN** the agent completes document analysis and sanctions verification
**THEN** the agent SHALL use a SaveDocument action group (lambda) to save the KYB verdict in the output bucket with Athena-queryable partitioning

**WHEN** the user uploads PDFs with customer-specific prefixes to the input bucket
**THEN** BDA SHALL maintain the customer_id prefix structure in the processing bucket for both custom output and standard output

## Agent Instructions

The Bedrock Agent SHALL be configured with the following instructions:

**Your role**: You are a KYB (Know Your Business) compliance agent responsible for analyzing company documents and verifying that company representatives are not subject to sanctions or politically exposed person (PEP) risks.

**Document Analysis**:
1. Review all available documents retrieved via the GetDocuments action group
2. The GetDocuments action group provides both custom output (structured extraction) and standard output (OCR text) for each document
3. Prioritize custom output for structured data extraction when available, but use standard output text for additional context
4. Identify company representatives (directors, legal representatives, beneficial owners) from the documents
5. Extract the following information for each representative:
   - Full name (name and surname)
   - Document ID (national ID, passport number, tax ID) if available

**Sanctions Verification**:
1. For each identified representative, use the CheckSanctions action group to verify:
   - Sanctions status (num_sanctions)
   - PEP score (pep_score)
2. Pass either the representative's full name (name + surname) OR document ID to the CheckSanctions action group
3. If name is used, pass both name and surname in the request

**Decision Logic**:
- **APPROVED**: All representatives identified AND all have num_sanctions = 0 AND acceptable pep_score (< 0.7)
- **REJECTED**: Any representative has num_sanctions > 0 OR pep_score >= 0.7
- **REVIEW_REQUIRED**: Cannot identify representatives in documents OR insufficient information to perform sanctions check

**Verdict Format**:
The verdict saved via SaveDocument SHALL include:
```json
{
  "customer_id": "string",
  "verdict": "APPROVED|REJECTED|REVIEW_REQUIRED",
  "timestamp": "ISO8601 timestamp",
  "representatives": [
    {
      "name": "string",
      "surname": "string",
      "document_id": "string (optional)",
      "num_sanctions": "number",
      "pep_score": "number"
    }
  ],
  "rejection_reason": "string (if REJECTED)",
  "review_notes": "string (if REVIEW_REQUIRED)"
}
```

## Technical Notes

### Existing Architecture (from v1)
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
- SaveDocument action group SHALL save verdicts using Athena-queryable partitioning: `{customer_id}/yyyy=YYYY/mm=MM/dd=DD/{uuid}.json`

### New in v2: CheckSanctions Action Group (Demo Mode)
- CheckSanctions Lambda SHALL accept either:
  - `name` + `surname` (both required if using name-based lookup), OR
  - `document_id` (single parameter alternative)
- CheckSanctions Lambda SHALL return **mocked random sanctions data** for demo purposes
- Mocking function SHALL be isolated for easy replacement with real API integration
- CheckSanctions SHALL return a JSON response with structure:
  ```json
  {
    "num_sanctions": 0,
    "pep_score": 0.23,
    "query_type": "name|document_id",
    "query_value": "string"
  }
  ```
- Mocked data SHALL include random scenarios: clean records, medium risk, high risk, with sanctions
- IAM role for CheckSanctions Lambda SHALL only require CloudWatch Logs access (no external API or Secrets Manager)
- CheckSanctions action group SHALL receive session parameters (customer_id) for logging/auditing

### PEP Score Interpretation
- **pep_score**: Float between 0.0 and 1.0
  - 0.0 - 0.3: Low risk
  - 0.3 - 0.7: Medium risk (acceptable)
  - 0.7 - 1.0: High risk (grounds for REJECTION)

### Sanctions Count Interpretation
- **num_sanctions**: Integer >= 0
  - 0: No sanctions (acceptable)
  - > 0: Has active sanctions (grounds for REJECTION)

## Non-Functional Requirement: Minimal Implementation

This implementation SHALL follow a **minimal, concise approach**:
- Use existing architectural patterns from v1
- Reuse IAM role patterns and response formats
- Follow the same OpenAPI schema structure for the new action group
- Maintain consistency with GetDocuments and SaveDocument implementations
- No error handling beyond basic AWS SDK defaults
- No extensive logging beyond minimal operational needs
- Minimal comments - only when necessary for clarity
