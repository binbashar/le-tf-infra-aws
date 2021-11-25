resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw-accepters" {

  transit_gateway_attachment_id = data.terraform_remote_state.tgw.outputs.tgw_attachment_id

  tags = merge({ Name = "tgw - tgw-dr accepter" }, local.tags)
}
