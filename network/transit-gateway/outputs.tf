output "tgw_id" {
  description = "Transit Gateway Id"
  value       = local.enable_tgw ? module.tgw[0].transit_gateway_id : null
}

output "tgw_route_table_id" {
  description = "TGW default route table id"
  value       = local.enable_tgw ? module.tgw[0].transit_gateway_route_table_id : null
}

output "tgw_inspection_route_table_id" {
  description = "TGW inspection route table id"
  value       = local.enable_tgw && local.enable_network_firewall && local.enable_network ? module.tgw_inspection_route_table[0].transit_gateway_route_table_id : null
}

output "enable_tgw" {
  description = "This is set to `true` if the Transit Gateway is enabled"
  value       = local.enable_tgw
}

output "enable_vpc_attach" {
  description = "VPC attachments per account"
  value       = local.enable_vpc_attach
}

output "tgw_attachment_id" {
  description = "TGW attachmenti id"
  value       = try(aws_ec2_transit_gateway_peering_attachment.tgw-dr[0].id, null)
}
