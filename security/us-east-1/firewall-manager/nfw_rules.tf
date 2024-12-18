module "firewall" {

  source = "github.com/binbashar/terraform-aws-network-firewall.git?ref=v0.1.4"

  name                    = "${var.project}-${var.environment}-firewall"
  create_network_firewall = false
  description             = "AWS Network Firewall Rules"
  vpc_id                  = null
  subnet_mapping          = null

  stateless_default_actions          = ["aws:pass"]
  stateless_fragment_default_actions = ["aws:drop"]

  # Stateless rule groups
  stateless_rule_groups = {
    # stateless-group-1 rules
    staless-group-1 = {
      description = "Staless rules"
      priority    = 10
      capacity    = 100
      rules = [
        {
          priority  = 1
          actions   = ["aws:drop"]
          protocols = [1] # ICMP
          source = {
            address = "0.0.0.0/0"
          }
          destination = {
            address = "0.0.0.0/0"
          }
        },
        {
          priority = 10
          actions  = ["aws:forward_to_sfe"]
          source = {
            address = "0.0.0.0/0"
          }
          destination = {
            address = "0.0.0.0/0"
          }
        },
      ]
    }
  }

  # Stateful rules
  stateful_rule_groups = {
    # rules_source_list examples
    stateful-group-1 = {
      description = "Stateful Inspection for denying access to domains 1/2"
      capacity    = 100
      rule_variables = {
        ip_sets = {
          HOME_NET = ["0.0.0.0/0"]
        }
      }
      rules_source_list = {
        generated_rules_type = "DENYLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets              = [".wikipedia.org", ".bad-domain.com"]
      }
    },
    stateful-group-2 = {
      description = "Stateful Inspection for denying access to domains 2/2"
      capacity    = 100
      rule_variables = {
        ip_sets = {
          HOME_NET = ["0.0.0.0/0"]
        }
      }
      rules_source_list = {
        generated_rules_type = "DENYLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets              = [".wikipedia2.org", ".bad-domain2.com"]
      }
    }
  }
}

