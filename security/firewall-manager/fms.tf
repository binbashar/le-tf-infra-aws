# Asssociate Firewall Manager Service adminidtator account
resource "aws_fms_admin_account" "default" {
  account_id = var.security_account_id
  provider   = aws.management
}

module "fms" {
  #source = "github.com/binbashar/terraform-aws-firewall-manager.git?ref=0.2.0"
  source = "git::https://github.com/binbashar/terraform-aws-firewall-manager.git?ref=fix/default-values"


  # Disable association of the FMS administrator account from the module
  admin_account_enabled = false

  # Security Groups Usage Audit Policies
  security_groups_usage_audit_policies = []

  # Network Firewall Policies
  # Refeferences:
  #  - https://github.com/binbashar/terraform-aws-firewall-manager#input_network_firewall_policies
  #  - https://docs.aws.amazon.com/fms/2018-01-01/APIReference/API_Policy.html#:~:text=Required%3A%20No-,ResourceType,-The%20type%20of
  network_firewall_policies = [
    {
      name                        = "nfw-policy"
      delete_all_policy_resources = false
      exclude_resource_tags       = false
      remediation_enabled         = true
      resource_type_list          = ["AWS::EC2::VPC"]
      resource_tags               = null
      include_account_ids         = { account = [var.network_account_id] }
      exclude_account_ids         = null

      policy_data = {
        stateless_rule_group_references     = []
        stateless_default_actions           = ["aws:pass"]
        stateless_fragment_default_actions  = ["aws:drop"]
        stateless_custom_actions            = []
        stateful_rule_group_references_arns = null
        orchestration_config = {
          single_firewall_endpoint_per_vpc = false
          allowed_ipv4_cidrs               = []
        }
      }
    }

  ]

  depends_on = [aws_fms_admin_account.default]

  providers = {
    aws.admin = aws
  }
}
