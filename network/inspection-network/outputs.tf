# VPC ID
output "inspection_vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "inspection_vpc_name" {
  description = "VPC Name"
  value       = local.vpc_name
}

output "inspection_vpc_cidr_block" {
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
