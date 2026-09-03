#
# Cost Optimization Hub: organization-wide enrollment
#
# Enrolling the payer account with include_member_accounts is what makes the Hub
# aggregate savings recommendations for every member account -- trusted access alone
# aggregates nothing. AWS enables trusted access implicitly as part of an org-wide
# opt-in; we also declare the principal explicitly in `organization.tf`
# (aws_service_access_principals) so the org's trusted services stay readable in one
# place rather than being a side effect of this resource.
#
# Consumed from the management (payer) account by the `aws-finops` Claude Code
# plugin (`/aws-finops-optimize`) through the awslabs.billing-cost-management-mcp-server
# MCP server. Recommendations refresh daily and are imported from Compute Optimizer and
# Savings Plans, so the Hub is only ever as fresh as those upstreams.
#
# Free of charge; opting out is just `tofu destroy` of this resource. The service is
# only available through the us-east-1 endpoint, which is the region this layer runs in
# (management/config/backend.tfvars).
#
resource "aws_costoptimizationhub_enrollment_status" "this" {
  include_member_accounts = true

  depends_on = [
    aws_organizations_organization.main,
  ]
}
