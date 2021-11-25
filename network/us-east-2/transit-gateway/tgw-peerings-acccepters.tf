# TGW peering attachment
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw-accepters" {

  transit_gateway_attachment_id = data.terraform_remote_state.tgw.outputs.tgw_attachment_id

  tags = merge({ Name = "tgw - tgw-dr accepter" }, local.tags)
}

# TGW association
resource "aws_ec2_transit_gateway_route_table_association" "tgw-association" {
  count = var.enable_tgw && try(data.terraform_remote_state.tgw.outputs.tgw_id != null, false) ? 1 : 0

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment_accepter.tgw-accepters.id, null)
}
