# TGW peering attachment
resource "aws_ec2_transit_gateway_peering_attachment" "tgw-dr" {

  count = local.enable_tgw && local.enable_tgw_multi_region && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) ? 1 : 0

  transit_gateway_id      = module.tgw[0].transit_gateway_id
  peer_region             = local.region_secondary
  peer_transit_gateway_id = data.terraform_remote_state.tgw-dr.outputs.tgw_id

  tags = merge({ Name = "tgw - tgw-dr peering" }, local.tags)
}

# TGW association
resource "aws_ec2_transit_gateway_route_table_association" "tgw-dr-association" {
  count = local.enable_tgw && local.enable_tgw_multi_region && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) ? 1 : 0

  transit_gateway_route_table_id = local.enable_network_firewall ? module.tgw_inspection_route_table[0].transit_gateway_route_table_id : module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment.tgw-dr[0].id, null)
}

# Add routes

#
# network-dr
#
resource "aws_ec2_transit_gateway_route" "network-dr" {

  for_each = { for k, v in local.network-dr-vpcs : k => v if local.enable_tgw && local.enable_tgw_multi_region && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.network-dr-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment.tgw-dr[0].id, null)
}

#
# shared-dr
#
resource "aws_ec2_transit_gateway_route" "shared-dr" {

  for_each = { for k, v in local.shared-dr-vpcs : k => v if local.enable_tgw && local.enable_tgw_multi_region && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.shared-dr-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment.tgw-dr[0].id, null)
}

#
# apps-devstg-dr
#
resource "aws_ec2_transit_gateway_route" "apps-devstg-dr" {

  for_each = { for k, v in local.apps-devstg-dr-vpcs : k => v if local.enable_tgw && local.enable_tgw_multi_region && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.apps-devstg-dr-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment.tgw-dr[0].id, null)
}
