# Firewall
resource "aws_networkfirewall_firewall" "firewall" {

  count = var.enable_network_firewall ? 1 : 0

  name                = "${var.project}-${var.environment}-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy.arn
  vpc_id              = module.vpc.vpc_id

  # subnet_mapping
  dynamic "subnet_mapping" {
    for_each = values(module.network_firewall_private_subnets.az_subnet_ids)

    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = local.tags
}

# Policy
resource "aws_networkfirewall_firewall_policy" "policy" {

  count = var.enable_network_firewall ? 1 : 0

  name = "${var.project}-${var.environment}-network-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.staless_rule_group.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.staleful_rule_group.arn
    }
  }

  tags = local.tags
}

# Stateless rule groups
resource "aws_networkfirewall_rule_group" "staless_rule_group" {

  yycount = var.enable_network_firewall ? 1 : 0

  name = "${var.project}-${var.environment}-default-forward"

  description = "Stateless Rule"
  capacity    = 100
  type        = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 10
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              #source_port {
              #  from_port = 0
              #  to_port   = 0
              #}
              destination {
                address_definition = "0.0.0.0/0"
              }
              #destination_port {
              #  from_port = 0
              #  to_port   = 0
              #}
            }
          }
        }
      }
    }
  }

  tags = local.tags
}

# Stateful rule groups
resource "aws_networkfirewall_rule_group" "staleful_rule_group" {

  count = var.enable_network_firewall ? 1 : 0

  name        = "${var.project}-${var.environment}-deny-wikipedia"
  capacity    = 50
  description = "Deny Wikipedia access"
  type        = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = ["0.0.0.0/0"]
        }

      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets              = [".wikipedia.org"]
      }
    }
  }

  tags = local.tags
}
