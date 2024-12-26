module "firewall" {

  count = var.enable_network_firewall ? 1 : 0

  source = "github.com/binbashar/terraform-aws-network-firewall.git?ref=v0.1.4"

  name = "${var.project}-${var.environment}-firewall-dr"

  description                       = "AWS Network Firewall for DR"
  delete_protection                 = false
  firewall_policy_change_protection = false
  subnet_change_protection          = false
  vpc_id                            = module.vpc.vpc_id

  stateless_default_actions          = ["aws:pass"]
  stateless_fragment_default_actions = ["aws:drop"]

  subnet_mapping = module.network_firewall_private_subnets.az_subnet_ids

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
      description = "Stateful Inspection for denying access to domains"
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
    }
  }
}

