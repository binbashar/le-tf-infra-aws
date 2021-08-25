module "firewall" {

  source = "github.com/binbashar/terraform-aws-network-firewall.git?ref=v0.1.0"

  name = "${var.project}-${var.environment}-firewall"

  description                       = "AWS Network Firewall example"
  delete_protection                 = false
  firewall_policy_change_protection = false
  subnet_change_protection          = false
  vpc_id                            = module.vpc.vpc_id

  stateless_default_actions          = ["aws:pass"]
  stateless_fragment_default_actions = ["aws:drop"]

  subnet_mapping = module.network_firewall_private_subnets.az_subnet_ids

  stateless_rule_groups = {
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

}

