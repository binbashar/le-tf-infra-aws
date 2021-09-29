module "fms" {
  source = "github.com/binbashar/terraform-aws-firewall-manager.git?ref=0.2.10"

  # Disable association of the FMS administrator account from the module
  admin_account_enabled = false

  # Security Groups Usage Audit Policies
  security_groups_usage_audit_policies = [
    {
      name                        = "sgs-usage-audit-policy"
      delete_all_policy_resources = true
      exclude_resource_tags       = false
      remediation_enabled         = true
      resource_tags               = null
      resource_type_list          = ["AWS::EC2::SecurityGroup"]

      policy_data = {
        delete_unused_security_groups      = false
        coalesce_redundant_security_groups = true
      }
    }
  ]

  # Security Groups_common_policies
  #security_groups_common_policies = [
  #  {
  #    name               = "disabled-all"
  #    resource_type_list = ["AWS::EC2::SecurityGroup"]
  #
  #    policy_data = {
  #      revert_manual_security_group_changes         = false
  #      exclusive_resource_security_group_management = false
  #      apply_to_all_ec2_instance_enis               = false
  #      security_groups                              = [module.vpc.security_group_id]
  #    }
  #  }
  #]

  # Web Application Firewall V2 Policies
  waf_v2_policies = [
    {
      name                        = "waf-v2-policy"
      delete_all_policy_resources = true
      exclude_resource_tags       = false
      remediation_enabled         = true
      resource_type_list          = ["AWS::ElasticLoadBalancingV2::LoadBalancer", "AWS::ApiGateway::Stage"]
      resource_type               = null
      resource_tags               = { "fms" = "True" }
      include_account_ids         = { accounts = [var.network_account_id, var.security_account_id] }
      exclude_account_ids         = {}
      logging_configuration       = null

      policy_data = {
        default_action                          = "allow"
        override_customer_web_acl_association   = true
        sampledRequestsEnabledForDefaultActions = null
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
            "ruleGroupType" : "ManagedRuleGroup",
            "sampledRequestsEnabled" : null
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
      delete_all_policy_resources = true
      exclude_resource_tags       = false
      remediation_enabled         = true # Must be set to `true`
      resource_type_list          = ["AWS::EC2::VPC"]
      resource_tags               = null
      include_account_ids         = { accounts = [var.network_account_id] }
      exclude_account_ids         = {}

      policy_data = {
        stateless_default_actions           = lookup(module.firewall.network_firewall_policy[0]["firewall_policy"][0], "stateless_default_actions", [])
        stateless_fragment_default_actions  = lookup(module.firewall.network_firewall_policy[0]["firewall_policy"][0], "stateless_fragment_default_actions", [])
        stateless_rule_group_references     = [for v in lookup(module.firewall.network_firewall_policy[0]["firewall_policy"][0], "stateless_rule_group_reference", []) : { "resourceARN" = v["resource_arn"], "priority" = v["priority"] }]
        stateless_custom_actions            = lookup(module.firewall.network_firewall_policy[0]["firewall_policy"][0], "stateless_custom_actions", [])
        stateful_rule_group_references_arns = [for v in lookup(module.firewall.network_firewall_policy[0]["firewall_policy"][0], "stateful_rule_group_reference", []) : v["resource_arn"]]
        orchestration_config = {
          single_firewall_endpoint_per_vpc = true # Set to `false` for deploying a NFW per subnet
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


  # AWS DNS Firewall
  dns_firewall_policies = [
    {
      name                        = "dns-policy"
      delete_all_policy_resources = true
      exclude_resource_tags       = false
      remediation_enabled         = true
      resource_type               = "AWS::EC2::VPC"
      resource_tags               = null
      include_account_ids         = { accounts = [var.network_account_id] }
      exclude_account_ids         = {}
      logging_configuration       = null
      policy_data = {
        pre_process_rule_groups = [
        { "ruleGroupId" : aws_route53_resolver_firewall_rule_group.example.id, "priority" : 10 }]
      }
    }
  ]

  #  depends_on = [module.firewall, aws_route53_resolver_firewall_rule_group.example]

  providers = {
    aws.admin = aws
  }
}

module "fms_cloudfront" {
  source = "github.com/binbashar/terraform-aws-firewall-manager.git?ref=0.2.10"

  # Disable association of the FMS administrator account from the module
  admin_account_enabled = false

  # Security Groups Usage Audit Policies
  security_groups_usage_audit_policies = []

  # Web Application Firewall V2 Policies
  waf_v2_policies = [
    { name                        = "cf-lnx-policy"
      delete_all_policy_resources = true
      exclude_resource_tags       = false
      remediation_enabled         = false
      resource_type               = "AWS::CloudFront::Distribution"
      resource_tags               = null
      include_account_ids         = { accounts = [var.network_account_id] }
      exclude_account_ids         = {}
      logging_configuration       = null

      policy_data = {
        default_action                        = "allow"
        override_customer_web_acl_association = true
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
