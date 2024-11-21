# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

#
# VPC Module
#
output "vpc_name" {
  description = "VPC Name"
  value       = local.vpc_name
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = var.vpc_cidr
}

output "azs" {
  description = "List of availability zones"
  value       = local.azs_internal
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
  description = "List of IDs of private subnets"
  value       = local.private_subnet_cidrs
}

output "public_subnets_cidr" {
  description = "List of IDs of public subnets"
  value       = local.public_subnet_cidrs
}

output "natgw_ids" {
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

output "peerings_created_for" {
  value = local.shared_vpcs_peerings
}
