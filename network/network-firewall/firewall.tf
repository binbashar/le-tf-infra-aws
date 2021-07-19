# Firewall
resource "aws_networkfirewall_firewall" "firewall" {
  name                = "network-firewall"
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
  name = "network-firewall-policy-example"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.rule_group.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.rule_group2.arn
    }
  }

  tags = local.tags
}

# Rule group
resource "aws_networkfirewall_rule_group" "rule_group" {
  capacity = 100
  name     = "test-example"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST"]
        targets              = ["www.example.com"]
      }
    }
  }

  tags = local.tags
}

# Rule group 2
resource "aws_networkfirewall_rule_group" "rule_group2" {
  capacity = 100
  name     = "rule-group2-example"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST"]
        targets              = ["test.example.com"]
      }
    }
  }

  tags = local.tags
}
