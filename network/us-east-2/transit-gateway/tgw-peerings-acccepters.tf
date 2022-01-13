# TGW peering attachment
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw-accepters" {

  count = var.enable_tgw && var.enable_tgw_multi_region && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) ? 1 : 0

  transit_gateway_attachment_id = data.terraform_remote_state.tgw.outputs.tgw_attachment_id

  tags = merge({ Name = "tgw - tgw-dr accepter" }, local.tags)
}

# TGW association
resource "aws_ec2_transit_gateway_route_table_association" "tgw-association" {
  count = var.enable_tgw && var.enable_tgw_multi_region && try(data.terraform_remote_state.tgw.outputs.tgw_id != null, false) ? 1 : 0

  transit_gateway_route_table_id = var.enable_network_firewall ? module.tgw_inspection_route_table[0].transit_gateway_route_table_id : module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment_accepter.tgw-accepters.id, null)
}

# Add routes

#
# network
#
resource "aws_ec2_transit_gateway_route" "network" {

  for_each = { for k, v in local.network-vpcs : k => v if var.enable_tgw && var.enable_tgw_multi_region && try(data.terraform_remote_state.tgw.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.network-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment_accepter.tgw-accepters.id, null)
}

#
# shared
#
resource "aws_ec2_transit_gateway_route" "shared" {

  for_each = { for k, v in local.shared-vpcs : k => v if var.enable_tgw && var.enable_tgw_multi_region && try(data.terraform_remote_state.tgw.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.shared-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment_accepter.tgw-accepters.id, null)
}

#
# apps-devstg
#
resource "aws_ec2_transit_gateway_route" "apps-devstg" {

  for_each = { for k, v in local.apps-devstg-vpcs : k => v if var.enable_tgw && var.enable_tgw_multi_region && try(data.terraform_remote_state.tgw.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.apps-devstg-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment_accepter.tgw-accepters.id, null)
}

#
# apps-prd
#
resource "aws_ec2_transit_gateway_route" "apps-prd" {

  for_each = { for k, v in local.apps-prd-vpcs : k => v if var.enable_tgw && var.enable_tgw_multi_region && try(data.terraform_remote_state.tgw.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.apps-prd-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment_accepter.tgw-accepters.id, null)
}
