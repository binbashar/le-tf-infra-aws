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
    ###Custom IP Rate Based Rule
    {
      name     = "CustomRulesIpRateLimitBasedRuleSet"
      priority = "0"

      action = "block"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "CustomRuleIpRateLimitBasedRuleSet-Metrics"
        sampled_requests_enabled   = true
      }

      rate_based_statement = {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    },
    {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = "1"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesAmazonIpReputationList-Metrics"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesAnonymousIpList"
      priority = "2"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesAnonymousIpList-Metrics"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = "3"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesBotControlRuleSet-Metrics"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = "4"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSet-Metrics"
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
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = "5"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesKnownBadInputsRuleSet-Metrics"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = "6"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesSQLiRuleSet-Metrics"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    },
  ]

  tags = local.tags
}