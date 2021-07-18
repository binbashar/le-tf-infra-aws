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

output "availability_zones" {
  description = "List of availability zones"
  value       = local.azs
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets_cidr" {
  description = "CIDRS of private subnets"
  value       = local.private_subnets_cidr
}

output "public_subnets_cidr" {
  description = "CIDR of public subnets"
  value       = local.public_subnets_cidr
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "enable_tgw" {
  description = "This is set to `true` if the Transit Gateway is enabled"
  value       = var.enable_tgw
}

output "enable_vpc_attach" {
  description = "VPC attachments per account"
  value       = var.enable_vpc_attach
}

output "enable_network_firewall" {
  description = "This is set to `true` if the AWS Network Firewall is enabled"
  value       = var.enable_network_firewall
}

output "tgw_route_tabe_id" {
  description = "TGW default route table id"
  value       = var.enable_tgw ? module.tgw[0].transit_gateway_route_table_id : null
}

output "tgw_inspection_route_tabe_id" {
  description = "TGW inspection route table id"
  value       = var.enable_tgw && lookup(var.enable_vpc_attach, "network", false) ? module.tgw_vpc_attachments_and_subnet_routes_network_inspection["network-inspection"].transit_gateway_route_table_id : null
}
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
