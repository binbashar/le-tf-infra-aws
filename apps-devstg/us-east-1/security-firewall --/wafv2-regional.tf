#
# Create a WAF v2 for ALB (EKS' ALB, etc...)
#
module "wafv2_regional_alb" {
  enabled = var.enable_wafv2_regional
  source  = "github.com/binbashar/terraform-aws-waf-webaclv2.git?ref=3.8.1"

  name_prefix = "${var.environment}-wafv2-albs"
  scope       = "REGIONAL"
  description = "WAFv2 ACL for ALB Ingress"

  alb_arn                = var.alb_waf_example.enabled ? module.alb_waf_example.lb_arn : ""
  create_alb_association = var.alb_waf_example.enabled ? true : false

  allow_default_action = true

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-wafv2-albs-main-metrics"
    sampled_requests_enabled   = true
  }

  rules = [
    {
      name     = "CommonRulesByAWS"
      priority = "1"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "CommonRulesByAWSMetric"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        excluded_rule = [
          "SizeRestrictions_BODY",
        ]
      }
    },
    {
      name     = "BadInputsRulesByAWS"
      priority = "2"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "BadInputsRulesByAWSMetric"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "SQLiRulesByAWS"
      priority = "3"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "BadInputsRulesByAWSMetric"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "IpReputationListbyAWS"
      priority = "4"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "IpReputationListByAWSMetric"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    },
    {
      name     = "BotControlByAWS"
      priority = "5"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesBotControlRuleSetMetric"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    },
    # Not supported from Terraform yet => https://github.com/hashicorp/terraform-provider-aws/issues/23287
    # {
    #   name     = "AWSManagedRulesATPRuleSetByAWS"
    #   priority = "5"

    #   override_action = "none"

    #   visibility_config = {
    #     cloudwatch_metrics_enabled = true
    #     metric_name                = "AWSManagedRulesATPRuleSet"
    #     sampled_requests_enabled   = true
    #   }

    #   managed_rule_group_statement = {
    #     name        = "AWSManagedRulesATPRuleSet"
    #     vendor_name = "AWS"
    #   }
    # },
    ### IP Rate Based Rule example
    {
      name     = "IpRateLimitBasedRuleCustom"
      priority = "7"

      action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "IpRateLimitBasedRuleMetric"
        sampled_requests_enabled   = true
      }

      rate_based_statement = {
        limit              = 100
        aggregate_key_type = "IP"
      }

      # Optional scope_down_statement to refine what gets rate limited
      # scope_down_statement = {
      #   not_statement = { # not statement to rate limit everything except the following path
      #     byte_match_statement = {
      #       field_to_match = {
      #         uri_path = "{}"
      #       }
      #       positional_constraint = "STARTS_WITH"
      #       search_string         = "/path/to/match"
      #       priority              = 0
      #       type                  = "NONE"
      #     }
      #   }
      # }
    },
  ]

  tags = local.tags
}