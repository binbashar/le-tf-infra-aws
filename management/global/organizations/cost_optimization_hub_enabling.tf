#
# Cost Optimization Hub: organization-wide enrollment
#
# Trusted access for `cost-optimization-hub.bcm.amazonaws.com` is granted in
# `organization.tf` (aws_service_access_principals); enrolling here is the second
# half of that switch and is what makes the payer account aggregate savings
# recommendations for every member account.
#
# Consumed from the management (payer) account by the `aws-finops` Claude Code
# plugin (`/aws-finops-optimize`) through the awslabs.billing-cost-management-mcp-server
# MCP server. Recommendations take 24-48h to populate after first enrollment.
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
