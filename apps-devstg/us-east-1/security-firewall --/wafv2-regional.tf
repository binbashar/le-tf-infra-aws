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
    }
  ]

  tags = local.tags
}