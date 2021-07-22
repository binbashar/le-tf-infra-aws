# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "VPC Name"
  value       = local.vpc_name
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = local.vpc_cidr_block
}

# Subnets
output "inspection_subnets" {
  description = "Map of AZ names to subnet IDs of inspection subnets"
  value       = module.inspection_private_subnets.az_subnet_ids
}

output "network_firewall_subnets" {
  description = "Map of AZ names to subnet IDs of network firewall subnets"
  value       = module.network_firewall_private_subnets.az_subnet_ids
}

output "private_subnets_cidr" {
  description = "CIDRS of private subnets"
  value       = local.private_subnets_cidr
}
output "inspection_subnets_cidr" {
  description = "CIDRS of inspection subnets"
  value       = local.inspection_subnets_cidr
}

output "network_firewall_subnets_cidr" {
  description = "CIDR of network firewall subnets"
  value       = local.network_firewall_subnets_cidr
}

output "network_firewall_route_table_ids" {
  description = "Map of AZ names to Route Table IDs of network_firewall route tables"
  value       = module.network_firewall_private_subnets.az_route_table_ids
}

output "inspection_route_table_ids" {
  description = "Map of AZ names to Route Table IDs of inspection route tables"
  value       = module.inspection_private_subnets.az_route_table_ids
}

# Network Firewall
output "network_firewall_status" {
  description = "Nested list of information about the current status of the firewall."
  value       = var.enable_network_firewall ? aws_networkfirewall_firewall.firewall[0].firewall_status : []
}

output "sync_states" {
  description = "Set of subnets configured for use by the firewall."
  value       = var.enable_network_firewall ? aws_networkfirewall_firewall.firewall[0].firewall_status.*.sync_states : []
}

output "network_firewall_subnet_id_endpoint_id" {
  description = "Map of endpoint_id per subnet_id"
  value       = var.enable_network_firewall ? { for v in aws_networkfirewall_firewall.firewall[0].firewall_status[0]["sync_states"].*.attachment : v[0]["subnet_id"] => v[0]["endpoint_id"] } : {}
}
