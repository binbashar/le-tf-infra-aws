#
# Compute Optimizer: organization-wide enrollment
#
# Compute Optimizer is what produces the right-sizing and idle-resource findings that
# `aws_costoptimizationhub_enrollment_status` (see cost_optimization_hub_enabling.tf)
# imports and prices. Enrolling the payer account alone would aggregate almost nothing:
# the workloads live in the member accounts, so `include_member_accounts` is what makes
# both the Hub and the plugin's right-sizing phase return anything at all.
#
# Consumed from the management (payer) account by the `aws-finops` Claude Code plugin
# (`/aws-finops-optimize`) through the awslabs.billing-cost-management-mcp-server MCP
# server, and by the Cost Optimization Hub as its upstream.
#
# Recommendations appear up to 24 h after opt-in, and each resource type has its own
# eligibility minimum on top of that (EC2/RDS 30 h of CloudWatch metrics, EBS 30
# consecutive hours attached, ECS on Fargate 24 h; Lambda needs no CloudWatch data but
# does need 50 invocations in 14 days). A run made right after this applies will still
# come back thin. See the README table, or:
# https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html
#
# Free of charge; opting out is just `tofu destroy` of this resource.
#
resource "aws_computeoptimizer_enrollment_status" "this" {
  status                  = "Active"
  include_member_accounts = true

  depends_on = [
    aws_organizations_organization.main,
  ]
}
