# Associate an AWS Firewall Manager administrator account.
resource "aws_fms_admin_account" "fms" {
  account_id = var.security_account_id
}

#
module "fms" {
  source = "github.com/binbashar/terraform-aws-firewall-manager.git?ref=v0.2.0"

  # Network Firewall Rules
  # Refeferences:
  #  - https://github.com/binbashar/terraform-aws-firewall-manager#input_network_firewall_policies
  #  - https://docs.aws.amazon.com/fms/2018-01-01/APIReference/API_Policy.html#:~:text=Required%3A%20No-,ResourceType,-The%20type%20of
  network_firewall_policies = [
    {
      name                        = "nfw-policy"
      delete_all_policy_resources = false
      exclude_resource_tags       = false
      remediation_enabled         = false
      resource_type_list          = ["AWS::EC2::VPC"]
      resource_tags               = null
      include_account_ids         = null
      exclude_account_ids         = null

      policy_data = {
        stateless_rule_group_references     = []
        tateless_default_actions            = []
        stateless_fragment_default_actions  = []
        stateless_custom_actions            = []
        stateful_rule_group_references_arns = null
      }
    }
  ]
}
