# Bedrock Agent Multiple Action Groups Research Documentation

## Research Objective  
Research the AWS-IA Bedrock module (aws-ia/bedrock/aws) to understand its action group capabilities and determine whether it only supports one action group per agent or if it can handle multiple action groups.

## Research Plan
- [x] Check for existing research files in .claude/specs/bedrock-agent-multiple-action-groups/
- [ ] Search AWS-IA Bedrock module documentation and configuration
- [ ] Analyze module source code for action group variable definitions  
- [ ] Investigate multiple action group support and limitations
- [ ] Research alternative approaches and best practices
- [ ] Document findings in research markdown file

## Key Findings

### Initial AWS Documentation Search Results
Found several relevant AWS documentation sources:

1. **AWS CloudFormation Reference**: `AWS::Bedrock::Agent AgentActionGroup` - Contains details of the inline agent's action group
2. **Amazon Bedrock User Guide**: "Add an action group to your agent" - Covers action group creation process
3. **AWS CLI Reference**: `list-agent-action-groups` command - Indicates multiple action groups are supported at the API level
4. **Multi-agent Collaboration**: Documentation exists for multi-agent collaboration scenarios

**Key Insight**: The CLI command `list-agent-action-groups` (plural) suggests that AWS Bedrock agents can have multiple action groups at the service level.

### AWS Service Documentation

**From AWS CLI Documentation**:
- Command: `list-agent-action-groups` - Lists ALL action groups for an agent
- This confirms AWS Bedrock agents natively support multiple action groups
- The API accepts `agent-id` and `agent-version` to list multiple action groups

**From AWS Bedrock User Guide**:
- Action groups can be added individually to existing agents
- Each action group can have its own Lambda function executor
- Action groups have individual states (ENABLED/DISABLED)
- Multiple action groups can be managed independently per agent

### AWS-IA Bedrock Module Analysis

**Module Version**: 0.0.29

**Critical Finding**: The AWS-IA Bedrock module has **limited support for multiple action groups**:

**Single Action Group Variables**:
```hcl
# Single action group configuration
create_ag                        = bool (default: false)
action_group_name               = string
action_group_state              = string  
action_group_description        = string
lambda_action_group_executor    = string
api_schema_payload              = string
api_schema_s3_bucket_name       = string
api_schema_s3_object_key        = string
parent_action_group_signature   = string
skip_resource_in_use            = bool
custom_control                  = string
```

**Multiple Action Group Support**:
The module includes these variables for multiple action groups:
```hcl
action_group_list              = list(object({...}))  # Complex object type
action_group_lambda_arns_list  = list(string)        # List of Lambda ARNs  
action_group_lambda_names_list = list(string)        # List of Lambda names
```

**Analysis**: The module supports both single and multiple action groups, but the multiple action groups feature uses a complex list structure.

### OpenTofu/Terraform Module Options

**Available Terraform Modules for Multiple Action Groups**:

1. **AWS-IA Official Module (aws-ia/bedrock/aws)**:
   - ✅ Supports multiple action groups via `action_group_list`
   - ❌ Limited documentation for multiple action groups usage
   - ❌ Complex configuration structure

2. **SourceFuse Arc Bedrock Module**:
   - ✅ Explicitly designed for multiple action groups 
   - ✅ Dynamic function schemas for action execution
   - ✅ Better integration patterns

### Implementation Considerations

**Terraform Provider Limitations**:
- **Critical Issue**: AWS Terraform provider has a race condition bug (#42845)
- **Error**: "Prepare operation can't be performed on Agent when it is in Preparing state"
- **Impact**: Cannot create multiple `aws_bedrockagent_agent_action_group` resources in single apply
- **Status**: Open bug, affects automation workflows

**Agent State Management**:
- AWS Bedrock agents go into "Preparing" state during action group creation
- Only one prepare operation can be active at a time
- Agent must complete preparation before next action group can be added

### Security & Compliance

**IAM Considerations**:
- Each action group requires Lambda execution permissions
- Multiple Lambda functions may need individual IAM roles
- Agent resource role must have permissions for all action groups

**Best Practices**:
- Use separate Lambda functions for different business domains
- Implement proper error handling in Lambda functions
- Consider action group confirmation settings for sensitive operations

### Cost Implications

**Multiple Action Groups Impact**:
- Each action group can have its own Lambda function
- Lambda invocation costs scale with number of action groups and usage
- OpenAPI schema storage in S3 (minimal cost)

**Optimization Strategies**:
- Consolidate related actions in fewer action groups where logical
- Use efficient Lambda runtimes and appropriate memory allocation
- Consider Lambda Provisioned Concurrency for high-traffic scenarios

### Integration Points

**With Existing Infrastructure**:
- Action groups integrate with existing Lambda functions
- Can reuse existing S3 buckets for OpenAPI schemas
- IAM roles can be shared or created per action group

**Multi-Agent Collaboration**:
- Each collaborator agent can have its own action groups
- Supervisor agents can coordinate multiple specialized agents
- Action groups enable domain-specific capabilities per agent

## Recommended Approach

### Answer to Primary Question
**Q: Does the AWS-IA Bedrock module only support one action group per agent?**
**A: No - the AWS-IA Bedrock module supports multiple action groups per agent, but with limitations.**

### Implementation Strategies

**Option 1: Use AWS-IA Module with Multiple Action Groups (Recommended)**
```hcl
module "bedrock" {
  source  = "aws-ia/bedrock/aws"
  version = "0.0.29"
  
  # Agent configuration
  foundation_model = "anthropic.claude-3-5-sonnet-20241022-v2:0"
  instruction     = "You are an agent with multiple capabilities..."
  
  # Multiple action groups configuration
  action_group_list = [
    {
      action_group_name        = "BookingActions"
      action_group_description = "Hotel booking related actions"
      action_group_state      = "ENABLED"
      lambda_arn              = aws_lambda_function.booking_lambda.arn
      api_schema_payload      = file("schemas/booking-schema.json")
    },
    {
      action_group_name        = "PaymentActions"  
      action_group_description = "Payment processing actions"
      action_group_state      = "ENABLED"
      lambda_arn              = aws_lambda_function.payment_lambda.arn
      api_schema_payload      = file("schemas/payment-schema.json")
    }
  ]
}
```

**Option 2: Use SourceFuse Arc Bedrock Module (Alternative)**
```hcl
module "bedrock" {
  source  = "sourcefuse/arc-bedrock/aws"
  
  # Multiple action groups with dynamic schemas
  enable_multiple_action_groups = true
  action_groups = {
    booking = {
      lambda_function_name = "booking-handler"
      api_schema_file     = "booking-schema.json"
    }
    payment = {
      lambda_function_name = "payment-handler"  
      api_schema_file     = "payment-schema.json"
    }
  }
}
```

**Option 3: Sequential Deployment Workaround (If needed)**
```hcl
# Deploy action groups with explicit dependencies
resource "aws_bedrockagent_agent_action_group" "booking" {
  # First action group configuration
}

resource "aws_bedrockagent_agent_action_group" "payment" {
  depends_on = [aws_bedrockagent_agent_action_group.booking]
  # Second action group configuration  
}
```

### Best Practices for Multiple Action Groups

1. **Use AWS-IA Module**: Prefer the official AWS-IA module for production deployments
2. **Group Related Actions**: Consolidate logically related actions in single action groups
3. **Implement Dependencies**: Use `depends_on` or `for_each` with careful state management
4. **Monitor Agent State**: Account for "Preparing" state during deployments
5. **Test Incrementally**: Deploy one action group at a time during initial development

### Limitations to Consider

1. **Terraform Provider Bug**: Race condition may require sequential deployment
2. **Complex Configuration**: Multiple action groups increase configuration complexity
3. **State Management**: Agent preparation states can cause deployment delays
4. **Documentation**: Limited examples for multiple action groups in AWS-IA module

## References

- **AWS-IA Bedrock Module**: https://github.com/aws-ia/terraform-aws-bedrock
- **AWS CLI Reference**: https://docs.aws.amazon.com/cli/v1/reference/bedrock-agent/list-agent-action-groups.html
- **AWS Bedrock User Guide**: https://docs.aws.amazon.com/bedrock/latest/userguide/agents-action-add.html
- **Terraform Provider Issue**: https://github.com/hashicorp/terraform-provider-aws/issues/42845
- **SourceFuse Module**: https://github.com/sourcefuse/terraform-aws-arc-bedrock
- **AWS Samples**: https://github.com/aws-samples/aws-generative-ai-terraform-samples