resource "aws_ec2_transit_gateway_peering_attachment" "tgw-dr" {

  count = var.enable_tgw && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) ? 1 : 0

  transit_gateway_id      = module.tgw[0].transit_gateway_id
  peer_region             = var.region_secondary
  peer_transit_gateway_id = data.terraform_remote_state.tgw-dr.outputs.tgw_id

  tags = local.tags
}
