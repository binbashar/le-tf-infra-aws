#
# Create a WAF v2 for ALB (EKS' ALB, etc...)
#
module "wafv2_regional_alb" {
  enabled = var.enable_wafv2_regional
  source  = "github.com/binbashar/terraform-aws-waf-webaclv2.git?ref=5.1.3"

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

  # Every rule starts in COUNT. Nothing here blocks on a first apply -- the
  # WebACL only observes and logs what it *would* have done, which is the only
  # honest way to size the blast radius before turning it on. Promote a rule to
  # `block` (or `action = "block"` for the rate limit) once its counted
  # requests in `aws-waf-logs-wafv2-apps` show no legitimate traffic caught.
  #
  # Two rule groups the upstream layer ships were dropped rather than counted:
  #
  #   AWSManagedRulesBotControlRuleSet -- its CategoryHttpLibrary signal targets
  #     exactly the non-browser clients every check against this cluster uses
  #     (`curl`), and it bills ~$10/month on top of the WebACL.
  #   AWSManagedRulesATPRuleSet -- was pointed at `login_path = "/api/1/signin"`,
  #     which no workload here serves, so it protected nothing for the same
  #     ~$10/month.
  #
  # Both are worth revisiting for a workload that has real logins and real
  # browser traffic; neither is worth it here.
  rules = [
    ###Custom IP Rate Based Rule
    {
      name     = "CustomRulesIpRateLimitBasedRuleSet"
      priority = "0"

      action = "count"

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

      override_action = "count"

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

      override_action = "count"

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
      name     = "AWSManagedRulesCommonRuleSet"
      priority = "3"

      override_action = "count"

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
      priority = "4"

      override_action = "count"

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
      priority = "5"

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesSQLiRuleSet-Metrics"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
  ]

  # Logging
  create_logging_configuration = true
  log_destination_configs      = [aws_cloudwatch_log_group.waf_logs.arn]
  logging_filter = {
    default_behavior = "DROP"

    filter = [
      # Keep logs for blocked requests
      {
        behavior    = "KEEP"
        requirement = "MEETS_ANY"
        condition = [
          {
            action_condition = {
              action = "BLOCK"
            }
          },
        ]
      },
      # Keep logs for counted requests
      {
        behavior    = "KEEP"
        requirement = "MEETS_ANY"
        condition = [
          {
            action_condition = {
              action = "COUNT"
            }
          },
        ]
      },
    ]
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-wafv2-apps"
  retention_in_days = 7
  tags              = local.tags
}
