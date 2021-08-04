output "tgw_id" {
  description = "Transit Gateway Id"
  value       = var.enable_tgw ? module.tgw[0].transit_gateway_id : null
}

output "tgw_route_table_id" {
  description = "TGW default route table id"
  value       = var.enable_tgw ? module.tgw[0].transit_gateway_route_table_id : null
}

output "tgw_inspection_route_table_id" {
  description = "TGW inspection route table id"
  value       = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? module.tgw_vpc_attachments_and_subnet_routes_network_firewall["network-firewall"].transit_gateway_route_table_id : null
}

output "enable_tgw" {
  description = "This is set to `true` if the Transit Gateway is enabled"
  value       = var.enable_tgw
}

output "enable_vpc_attach" {
  description = "VPC attachments per account"
  value       = var.enable_vpc_attach
}

