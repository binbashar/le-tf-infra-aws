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

This implementation SHALL follow a **minimal, concise approach** with these mandatory principles:

- **DRY (Don't Repeat Yourself)**: No code duplication, reuse existing patterns from Leverage Reference Architecture
- **KISS (Keep It Simple, Stupid)**: Simple solutions over complex ones, minimal abstractions
- **YAGNI (You Aren't Gonna Need It)**: Only implement what is explicitly required, no anticipatory features
- **MVP Focus**: No monitoring, testing, security overhead, documentation generation, or any non-essential features
- **Minimal Boilerplate**: Use only necessary OpenTofu resources, avoid defensive programming patterns
- **Essential Code Only**: Every line of code must serve a specific requirement, no placeholder code or future-proofing

**Implementation agents SHALL NOT add:**
- Error handling beyond basic AWS SDK defaults
- Logging beyond minimal operational needs
- Input validation beyond AWS service requirements
- Configuration options not explicitly requested
- Retry logic, circuit breakers, or resilience patterns
- Excessive comments (only when necessary for clarity or explicitly requested)
- Unit tests, integration tests, or test frameworks
- Monitoring, alerting, or observability features
- Security enhancements beyond AWS defaults

**Comment Guidelines:**
- Use minimal, necessary comments only when needed for clarity
- Comments should explain WHY, not WHAT
- Acceptable comment scenarios: progressive implementation patterns, non-obvious design decisions, temporary workarounds
- Prefer self-documenting code over excessive documentation

This requirement ensures the implementation stays focused on the core functionality without LLM-generated overhead.