# T-004-API: API Gateway Setup - Implementation Plan

## Overview

Create a minimal REST API Gateway with IAM authentication that exposes a single endpoint to trigger the Bedrock Agent via the Agent Invoker Lambda function.

## Requirements

- **Authentication**: AWS IAM (SigV4 request signing) - default same-account access
- **Endpoint**: POST /invoke-agent
- **Request Body**: `{"customer_id": "string"}`
- **Integration**: Direct Lambda integration with Agent Invoker
- **Validation**: Request body validation for customer_id parameter
- **MVP Approach**: Minimal implementation, no CORS, no custom authorizers, no resource policies

## Implementation Strategy

### 1. Module Selection

Use the **SPHTech terraform-aws-apigw module** (proven in workflow-order-processing-- layer):
- Source: `github.com/SPHTech-Platform/terraform-aws-apigw.git?ref=v0.4.13`
- Benefits: Built-in support for OpenAPI specs, IAM authentication, request validation
- Minimal configuration required

### 2. File Structure

Create a single new file:
- `api_gateway.tf` - API Gateway resource using module

Update existing file:
- `outputs.tf` - Add API Gateway outputs

### 3. Implementation Details

#### API Gateway Configuration

**Module Parameters:**
```hcl
module "apigw_kyb_agent" {
  source = "github.com/SPHTech-Platform/terraform-aws-apigw.git?ref=v0.4.13"

  name  = "KybAgentApi"
  stage = "v1"

  body_template = <<EOF
    # OpenAPI 2.0 spec (see below)
  EOF

  metrics_enabled             = true
  data_trace_enabled          = true
  enable_global_apigw_logging = true
  tags                        = local.tags
}
```

**OpenAPI Specification Structure:**
```yaml
swagger: "2.0"
info:
  version: "1.0.0"
  title: "KYB Agent API"
basePath: "/v1"
schemes:
  - "https"

paths:
  /invoke-agent:
    post:
      operationId: "invokeKybAgent"
      consumes:
        - "application/json"
      produces:
        - "application/json"
      parameters:
        - in: "body"
          name: "InvokeAgentRequest"
          required: true
          schema:
            $ref: "#/definitions/InvokeAgentRequest"
      responses:
        "200":
          description: "Agent invocation successful"
        "400":
          description: "Invalid request"
        "500":
          description: "Internal server error"
      security:
        - sigv4: []
      x-amazon-apigateway-request-validator: "Validate body"
      x-amazon-apigateway-integration:
        uri: "${aws_lambda_function.agent_invoker.invoke_arn}"
        requestTemplates:
          application/json: "$input.body"
        responses:
          default:
            statusCode: "200"
        passthroughBehavior: "when_no_templates"
        httpMethod: "POST"
        type: "aws_proxy"

securityDefinitions:
  sigv4:
    type: "apiKey"
    name: "Authorization"
    in: "header"
    x-amazon-apigateway-authtype: "awsSigv4"

definitions:
  InvokeAgentRequest:
    type: "object"
    required:
      - "customer_id"
    properties:
      customer_id:
        type: "string"
        minLength: 1

x-amazon-apigateway-request-validators:
  Validate body:
    validateRequestParameters: false
    validateRequestBody: true
```

**Key OpenAPI Features:**
1. **IAM Authentication**: `security: - sigv4: []` with `awsSigv4` auth type
2. **Request Validation**: Body validation for required `customer_id` parameter
3. **Lambda Integration**: AWS_PROXY integration with Agent Invoker function
4. **Error Handling**: Standard HTTP status codes (200, 400, 500)

#### IAM Configuration

**Resource Policy (API Gateway):**
AWS IAM authentication requires BOTH a resource policy on the API Gateway AND an identity-based policy on IAM principals.

```hcl
# Resource policy allows same-account access
resource_policy_json = jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect = "Allow"
    Principal = { AWS = "*" }
    Action   = "execute-api:Invoke"
    Resource = "*"
    Condition = {
      StringEquals = {
        "aws:SourceAccount" = data.aws_caller_identity.current.account_id
      }
    }
  }]
})
```

**Identity-Based Policy (IAM Principals):**
Create managed policy for SSO users/roles to attach:

```hcl
resource "aws_iam_policy" "api_invoke_policy" {
  name        = "${var.project}-${var.environment}-kyb-agent-api-invoke"
  description = "Allows invoking the KYB Agent API Gateway endpoint"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "execute-api:Invoke"
      Resource = "${module.apigw_kyb_agent.aws_api_gateway_stage_execution_arn}/*"
    }]
  })

  tags = local.tags
}
```

**Lambda Permission for API Gateway:**
```hcl
resource "aws_lambda_permission" "allow_apigw_invoke_agent" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agent_invoker.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.apigw_kyb_agent.execution_arn}/*/*"
}
```

**Access Grant Process:**
1. IaC creates the managed policy automatically
2. Admin manually attaches policy to SSO permission set (one-time per environment)
3. All users with that permission set can invoke the API

#### Local Variables

Add to `locals.tf`:
```hcl
api_name = "${var.project}-${var.environment}-kyb-agent-api"
```

#### Outputs

Add to `outputs.tf`:
```hcl
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = module.apigw_kyb_agent.api_id
}

output "api_gateway_endpoint" {
  description = "Invoke URL for the API Gateway endpoint"
  value       = "${module.apigw_kyb_agent.invoke_url}/invoke-agent"
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway (for Lambda permissions)"
  value       = module.apigw_kyb_agent.execution_arn
}

output "api_gateway_stage" {
  description = "Deployment stage of the API Gateway"
  value       = module.apigw_kyb_agent.stage_name
}

output "api_gateway_test_command" {
  description = "Example command to test the API Gateway endpoint with awscurl"
  value       = <<-EOT
    # Install awscurl: pip install awscurl
    # Test command (replace with actual endpoint URL):
    awscurl --service execute-api -X POST \
      -d '{"customer_id":"test-customer-123"}' \
      -H "Content-Type: application/json" \
      "${module.apigw_kyb_agent.invoke_url}/invoke-agent"
  EOT
}

output "api_invoke_policy_arn" {
  description = "IAM policy ARN for API invocation (attach to SSO permission sets)"
  value       = aws_iam_policy.api_invoke_policy.arn
}

output "sso_setup_instructions" {
  description = "Instructions for granting SSO users access to the API"
  value       = <<-EOT
    Grant API access to SSO users:

    1. Open IAM Identity Center console
    2. Go to: Permission sets
    3. Select: DataScientist (or your permission set name)
    4. Click: Permissions tab → Add permissions → Attach policies
    5. Search for: ${aws_iam_policy.api_invoke_policy.name}
    6. Attach policy

    All users with this permission set can now invoke the API using their normal SSO credentials.
  EOT
}
```

### 4. Integration Points

**Agent Invoker Lambda Update:**
- Lambda code already expects API Gateway proxy events (T-007 implemented)
- Environment variables already configured in `lambda.tf`
- No Lambda code changes required

**Module Dependencies:**
```hcl
depends_on = [
  aws_lambda_function.agent_invoker,
  aws_lambda_permission.allow_apigw_invoke_agent
]
```

### 5. Testing Approach

**Test Command (output will provide):**
```bash
# Using awscurl (requires pip install awscurl)
awscurl --service execute-api -X POST \
  -d '{"customer_id":"test-customer-123"}' \
  -H "Content-Type: application/json" \
  "https://your-api-id.execute-api.us-east-1.amazonaws.com/v1/invoke-agent"

# Expected Response:
{
  "status": "success",
  "session_id": "...",
  "agent_id": "...",
  "message": "Agent invocation started"
}
```

**Validation Tests:**
1. Test with valid customer_id → Should succeed (200)
2. Test with missing customer_id → Should fail validation (400)
3. Test without AWS credentials → Should fail authentication (403)
4. Test with invalid credentials → Should fail authentication (403)

### 6. Deployment Order

```bash
# From layer directory: data-science/us-east-1/bedrock-agent-kyb

# 1. Format and validate
leverage tf format
leverage tf validate

# 2. Plan with API Gateway target
leverage tf plan -target=module.apigw_kyb_agent -target=aws_lambda_permission.allow_apigw_invoke_agent

# 3. Apply API Gateway resources
leverage tf apply -target=module.apigw_kyb_agent -target=aws_lambda_permission.allow_apigw_invoke_agent -auto-approve

# 4. Verify outputs
leverage tf output api_gateway_endpoint
leverage tf output api_gateway_test_command

# 5. Test the endpoint
# Copy the test command from output and run it
```

## Implementation Checklist

### T-004-API.1: Create `api_gateway.tf` file
- [ ] Create new file `api_gateway.tf`
- [ ] Add module block for `apigw_kyb_agent`
- [ ] Define OpenAPI spec with `/invoke-agent` POST endpoint
- [ ] Configure IAM authentication (SigV4)
- [ ] Add request body validation for `customer_id`
- [ ] Configure Lambda proxy integration
- [ ] Enable metrics and logging

### T-004-API.2: Configure Lambda Permission
- [ ] Add `aws_lambda_permission` resource
- [ ] Allow API Gateway to invoke Agent Invoker Lambda
- [ ] Set correct source ARN pattern

### T-004-API.3: Add Local Variables (Optional)
- [ ] Add `api_name` to `locals.tf` if needed for consistency

### T-004-API.4: Add Outputs
- [ ] Add `api_gateway_id` output
- [ ] Add `api_gateway_endpoint` output
- [ ] Add `api_gateway_execution_arn` output
- [ ] Add `api_gateway_stage` output
- [ ] Add `api_gateway_test_command` output with example awscurl command
- [ ] Add `api_invoke_policy_arn` output
- [ ] Add `sso_setup_instructions` output

### T-004-API.8: Create IAM Managed Policy
- [ ] Create `aws_iam_policy` resource for API invocation
- [ ] Configure policy with `execute-api:Invoke` action
- [ ] Use dynamic resource ARN from API Gateway module
- [ ] Add policy outputs for operational use
- [ ] Document SSO permission set attachment process

### T-004-API.5: Validation and Deployment
- [ ] Run `leverage tf format`
- [ ] Run `leverage tf validate`
- [ ] Run `leverage tf plan` and review
- [ ] Run `leverage tf apply`
- [ ] Verify outputs are generated correctly

### T-004-API.6: Testing
- [ ] Install awscurl: `pip install awscurl`
- [ ] Test with valid request (should succeed)
- [ ] Test with missing customer_id (should fail validation)
- [ ] Test without credentials (should fail authentication)
- [ ] Verify Lambda logs show invocation

## Expected Outcomes

1. **API Gateway Created**: REST API with single POST endpoint
2. **IAM Authentication Active**: Requires SigV4 signing for all requests
3. **Request Validation Working**: Rejects requests without customer_id
4. **Lambda Integration Successful**: Agent Invoker receives and processes requests
5. **Outputs Available**: Test command and endpoint URL in outputs
6. **Documentation Complete**: Test commands and examples in outputs

## Non-Goals (Out of Scope for MVP)

- ❌ CORS configuration (not needed for server-to-server)
- ❌ Custom authorizers (IAM is sufficient)
- ❌ API keys or usage plans (IAM handles auth)
- ❌ Custom domain names (can use default)
- ❌ CloudFront integration (not required)
- ❌ WAF integration (not required for MVP)
- ❌ Rate limiting (API Gateway default limits sufficient)
- ❌ Request/response transformations (proxy integration handles this)
- ❌ Multiple endpoints (only one needed: /invoke-agent)
- ❌ Cross-account access (same-account only)

## Security Considerations

**Default Security Posture:**
- IAM authentication required for all requests (SigV4 signing)
- **Two-policy requirement**:
  - Resource policy on API Gateway (allows same-account principals)
  - Identity-based policy on IAM principals (grants execute-api:Invoke)
- Request validation prevents malformed requests
- CloudWatch logging enabled for audit trail
- Metrics enabled for monitoring

**Access Control Model:**
- **Defense in depth**: Both policies must allow for access to succeed
- Resource policy: Broad (any principal in account)
- Identity-based policy: Granular (explicit grants per role/user)
- Manual attachment to SSO permission sets provides control

**No Additional Security Needed for MVP:**
- Custom authorizers (IAM handles this)
- API keys (IAM handles this)
- Throttling configuration (API Gateway defaults sufficient)
- Cross-account access policies (same-account only)

## Minimal Implementation Principle

This implementation follows the **KISS principle**:
- Single endpoint (no unnecessary routes)
- Standard IAM authentication (no custom auth logic)
- Module-based approach (no custom API Gateway resources)
- Proxy integration (no request/response mapping)
- Default security (no over-engineering)
- Minimal configuration (only required fields)

## References

- **Similar Implementation**: `/Users/alex/Developer/le-tf-infra-aws/data-science/us-east-1/workflow-order-processing--/apigw.tf`
- **Module Documentation**: https://github.com/SPHTech-Platform/terraform-aws-apigw
- **API Gateway IAM Auth**: https://docs.aws.amazon.com/apigateway/latest/developerguide/permissions.html
- **Agent Invoker Lambda**: `/Users/alex/Developer/le-tf-infra-aws/data-science/us-east-1/bedrock-agent-kyb/src/agent-invoker/lambda_function.py`
- **OpenAPI Extensions**: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html

## Success Criteria

✅ API Gateway deployed with IAM authentication
✅ Resource policy allows same-account access
✅ IAM managed policy created for identity-based grants
✅ POST /invoke-agent endpoint accepts customer_id
✅ Request validation rejects invalid requests
✅ Lambda integration works with Agent Invoker
✅ Test command in outputs works correctly
✅ SSO setup instructions provided in outputs
✅ CloudWatch logs show successful invocations
✅ Access control follows defense-in-depth principle
