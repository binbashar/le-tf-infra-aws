module "fms" {
  #source = "github.com/binbashar/terraform-aws-firewall-manager.git?ref=0.2.0"
  source = "git::https://github.com/binbashar/terraform-aws-firewall-manager.git?ref=fix/default-values"

  # Disable association of the FMS administrator account from the module
  admin_account_enabled = false

  # Security Groups Usage Audit Policies
  security_groups_usage_audit_policies = [
    {
      name               = "unused-sg"
      resource_type_list = ["AWS::EC2::SecurityGroup"]

      policy_data = {
        delete_unused_security_groups      = false
        coalesce_redundant_security_groups = false
      }
    }
  ]

  # Web Application Firewall V2 Policies
  waf_v2_policies = [
    {
      name                        = "linux-policy"
      delete_all_policy_resources = false
      exclude_resource_tags       = false
      remediation_enabled         = true
      resource_type_list          = ["AWS::ElasticLoadBalancingV2::LoadBalancer", "AWS::ApiGateway::Stage"]
      resource_type               = null
      resource_tags               = null
      include_account_ids         = { accounts = [var.network_account_id, var.security_account_id] }
      exclude_account_ids         = {}
      logging_configuration       = null

      policy_data = {
        default_action                        = "allow"
        override_customer_web_acl_association = false
        pre_process_rule_groups = [
          {
            "managedRuleGroupIdentifier" : {
              "vendorName" : "AWS",
              "managedRuleGroupName" : "AWSManagedRulesLinuxRuleSet",
              "version" : null
            },
            "overrideAction" : { "type" : "NONE" },
            "ruleGroupArn" : null,
            "excludeRules" : [],
            "ruleGroupType" : "ManagedRuleGroup"
          }
        ]
      }
    }
  ]

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
      include_account_ids         = { accounts = [var.network_account_id] }
      exclude_account_ids         = {}

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

  # AWS Shield Advanced (SUBSCRIPTION REQUIRED!)
  #  shield_advanced_policies = [
  #  {
  #    name                        = "shield-advance-policy"
  #    delete_all_policy_resources = false
  #    exclude_resource_tags       = false
  #    remediation_enabled         = true
  #    resource_type_list          = ["AWS::ElasticLoadBalancingV2::LoadBalancer"]
  #    resource_tags               = null
  #    include_account_ids         = { accounts = [var.network_account_id] }
  #    exclude_account_ids         = {}
  #  }
  #]

  depends_on = [aws_fms_admin_account.default]

  providers = {
    aws.admin = aws
  }
}

module "fms_cloudfront" {
  #source = "github.com/binbashar/terraform-aws-firewall-manager.git?ref=0.2.0"
  source = "git::https://github.com/binbashar/terraform-aws-firewall-manager.git?ref=fix/default-values"

  # Disable association of the FMS administrator account from the module
  admin_account_enabled = false

  # Security Groups Usage Audit Policies
  security_groups_usage_audit_policies = []

  # Web Application Firewall V2 Policies
  waf_v2_policies = [
    { name                        = "cf-linux-policy"
      delete_all_policy_resources = false
      exclude_resource_tags       = false
      remediation_enabled         = false
      resource_type               = "AWS::CloudFront::Distribution"
      resource_tags               = null
      include_account_ids         = { accounts = [var.network_account_id] }
      exclude_account_ids         = {}
      logging_configuration       = null

      policy_data = {
        default_action                        = "allow"
        override_customer_web_acl_association = false
        pre_process_rule_groups = [
          {
            "managedRuleGroupIdentifier" : {
              "vendorName" : "AWS",
              "managedRuleGroupName" : "AWSManagedRulesLinuxRuleSet",
              "version" : null
            },
            "overrideAction" : { "type" : "NONE" },
            "ruleGroupArn" : null,
            "excludeRules" : [],
            "ruleGroupType" : "ManagedRuleGroup"
          }
        ]
      }
    }
  ]

  providers = {
    aws.admin = aws
  }
}
