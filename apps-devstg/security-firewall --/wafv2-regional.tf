#
# Create a WAF v2 for EKS' ALB
#
module "wafv2_regional_alb" {
  source = "github.com/binbashar/terraform-aws-waf-webaclv2.git?ref=1.5.1"

  name_prefix = "${var.environment}-wafv2-albs"
  scope       = "REGIONAL"

  # alb_arn     = module.alb.arn
  create_alb_association = false

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
      priority = "2"

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
