# Network Firewall VPC attachment - Inspection subnets (private)
module "vpn_gateways" {

  source = "github.com/binbashar/terraform-aws-vpn-gateway?ref=v2.10.0"

  #for_each = var.customer_gateways
  for_each = { for k, v in var.customer_gateways :
    k => v if var.enable_tgw && var.vpc_enable_vpn_gateway
  }

  connect_to_transit_gateway = true
  transit_gateway_id         = module.tgw[0].transit_gateway_id

  customer_gateway_id = module.vpc.this_customer_gateway[each.key].id

  # Tunnel 1 (optional)
  tunnel1_inside_cidr   = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "inside_cidr", null)
  tunnel1_preshared_key = lookup(each.value, "tunnel1", null) == null ? null : lookup(lookup(each.value, "tunnel1"), "preshared_key", null)

  # Tunnel 2 (optional)
  tunnel2_inside_cidr   = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "inside_cidr", null)
  tunnel2_preshared_key = lookup(each.value, "tunnel2", null) == null ? null : lookup(lookup(each.value, "tunnel2"), "preshared_key", null)

}

# vpn static routes
resource "aws_ec2_transit_gateway_route" "vpn_static_routes" {

  for_each = { for k, v in local.vpn_static_routes :
    k => v if var.enable_tgw && var.vpc_enable_vpn_gateway
  }

  destination_cidr_block         = lookup(each.value, "route")
  transit_gateway_route_table_id = var.enable_tgw && var.enable_network_firewall ? module.tgw_vpc_attachments_and_subnet_routes_network_firewall["network-firewall"].transit_gateway_route_table_id : module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.vpn_gateways[lookup(each.value, "cgw")].vpn_connection_transit_gateway_attachment_id
}

