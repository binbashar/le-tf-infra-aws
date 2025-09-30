# KYB Agent Requirements

## Use Cases

**WHEN** the user saves PDF files in an input bucket
**THEN** the system SHALL start an EventBridge trigger that invokes a lambda to start BDA processing

**WHEN** BDA processes files using standard output and saves extraction in a processing bucket
**THEN** the system SHALL start another EventBridge trigger that invokes a lambda to invoke the Bedrock Agent

**WHEN** the Bedrock Agent is invoked with session parameters
**THEN** the agent SHALL use a GetDocuments action group (lambda) to retrieve processed documents from the processing bucket using standard output folder structure

**WHEN** the agent retrieves documents
**THEN** the agent SHALL use a SaveDocument action group (lambda) to save the extraction (bypass) in the output bucket

## Technical Notes

- BDA will use **standard output** (not custom blueprint) for document extraction
- Standard output saves OCR extraction in a different folder structure than custom output
- Agent uses **session parameters** to automatically inject parameters to action groups
- GetDocuments action group receives `output_type` parameter set to "Standard"
- Session parameters avoid the need for explicit parameter passing between agent and action groups

## Non-Functional Requirement: Minimal Implementation

This implementation SHALL follow a **minimal, concise approach**.