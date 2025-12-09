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
