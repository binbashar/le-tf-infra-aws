#
# Create a WAF v2 for ALB (EKS' ALB, etc...)
#
module "wafv2_regional_alb" {
  count  = var.enable_wafv2_regional ? 1 : 0
  source = "github.com/binbashar/terraform-aws-waf-webaclv2.git?ref=3.8.1"

  name_prefix = "${var.environment}-wafv2-albs"
  scope       = "REGIONAL"
  description = "WAFv2 ACL for ALB Ingress"

  alb_arn                = var.alb_waf_example.enabled ? module.alb_waf_example[0].arn : ""
  create_alb_association = var.alb_waf_example.enabled ? true : false

  allow_default_action = true

  visibility_config = {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.environment}-wafv2-albs-main-metrics"
    sampled_requests_enabled   = true
  }

  rules = [
    {
      name     = "CommonRulesByAWS"
      priority = "1"

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = false
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

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "BadInputsRulesByAWSMetric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "SQLiRulesByAWS"
      priority = "3"

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "BadInputsRulesByAWSMetric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
  ]

  tags = local.tags
}