# Network Firewall VPC attachment - Inspection subnets (private)
module "vpn_gateways" {

  source = "github.com/binbashar/terraform-aws-vpn-gateway?ref=v2.10.0"

  for_each = { for k, v in var.customer_gateways :
    k => v if var.enable_tgw && var.vpc_enable_vpn_gateway
  }

  connect_to_transit_gateway        = true
  vpn_connection_static_routes_only = lookup(each.value, "vpn_connection_static_routes_only", false)
  transit_gateway_id                = data.terraform_remote_state.tgw.outputs.tgw_id
  customer_gateway_id               = module.vpc.this_customer_gateway[each.key].id

  ###########
  # Tunnels #
  ###########
  # Some values are optional and the default values are used if not specified

  # Tunnel 1
  tunnel1_inside_cidr                  = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "inside_cidr", null)
  tunnel1_preshared_key                = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "preshared_key", null)
  tunnel1_dpd_timeout_action           = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "dpd_timeout_action", null)
  tunnel1_dpd_timeout_seconds          = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "dpd_timeout_seconds", null)
  tunnel1_ike_versions                 = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "ike_versions", null)
  tunnel1_phase1_dh_group_numbers      = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase1_dh_group_numbers", null)
  tunnel1_phase1_encryption_algorithms = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase1_encryption_algorithms", null)
  tunnel1_phase1_integrity_algorithms  = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase1_integrity_algorithms", null)
  tunnel1_phase1_lifetime_seconds      = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase1_lifetime_seconds", null)
  tunnel1_phase2_dh_group_numbers      = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase2_dh_group_numbers", null)
  tunnel1_phase2_encryption_algorithms = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase2_encryption_algorithms", null)
  tunnel1_phase2_integrity_algorithms  = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase2_integrity_algorithms", null)
  tunnel1_phase2_lifetime_seconds      = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "phase2_lifetime_seconds", null)
  tunnel1_rekey_fuzz_percentage        = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "rekey_fuzz_percentage", null)
  tunnel1_rekey_margin_time_seconds    = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "rekey_margin_time_seconds", null)
  tunnel1_replay_window_size           = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "replay_window_size", null)
  tunnel1_startup_action               = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "startup_action", null)

  #
  # Tunnel 2
  #
  tunnel2_inside_cidr                  = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "inside_cidr", null)
  tunnel2_preshared_key                = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "preshared_key", null)
  tunnel2_dpd_timeout_action           = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "dpd_timeout_action", null)
  tunnel2_dpd_timeout_seconds          = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "dpd_timeout_seconds", null)
  tunnel2_ike_versions                 = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "ike_versions", null)
  tunnel2_phase1_dh_group_numbers      = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase1_dh_group_numbers", null)
  tunnel2_phase1_encryption_algorithms = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase1_encryption_algorithms", null)
  tunnel2_phase1_integrity_algorithms  = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase1_integrity_algorithms", null)
  tunnel2_phase1_lifetime_seconds      = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase1_lifetime_seconds", null)
  tunnel2_phase2_dh_group_numbers      = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase2_dh_group_numbers", null)
  tunnel2_phase2_encryption_algorithms = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase2_encryption_algorithms", null)
  tunnel2_phase2_integrity_algorithms  = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase2_integrity_algorithms", null)
  tunnel2_phase2_lifetime_seconds      = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "phase2_lifetime_seconds", null)
  tunnel2_rekey_fuzz_percentage        = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "rekey_fuzz_percentage", null)
  tunnel2_rekey_margin_time_seconds    = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "rekey_margin_time_seconds", null)
  tunnel2_replay_window_size           = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "replay_window_size", null)
  tunnel2_startup_action               = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "startup_action", null)
}

# vpn static routes
resource "aws_ec2_transit_gateway_route" "vpn_static_routes" {

  for_each = { for k, v in local.vpn_static_routes :
    k => v if var.enable_tgw && var.vpc_enable_vpn_gateway
  }

  destination_cidr_block         = lookup(each.value, "route")
  transit_gateway_route_table_id = var.enable_tgw && var.enable_network_firewall ? data.terraform_remote_state.tgw.outputs.tgw_inspection_route_table_id : data.terraform_remote_state.tgw.outputs.tgw_route_table_id
  transit_gateway_attachment_id  = module.vpn_gateways[lookup(each.value, "cgw")].vpn_connection_transit_gateway_attachment_id
}

#  TGW VPN RT associations
resource "aws_ec2_transit_gateway_route_table_association" "vpn-rt-associations" {

  for_each = { for k, v in var.customer_gateways :
    k => v if var.enable_tgw && var.vpc_enable_vpn_gateway
  }

  transit_gateway_route_table_id = data.terraform_remote_state.tgw.outputs.tgw_route_table_id
  transit_gateway_attachment_id  = module.vpn_gateways[lookup(each.value, "cgw")].vpn_connection_transit_gateway_attachment_id
}
