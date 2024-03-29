# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc-eks.vpc_id
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = local.cluster_name
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
  value       = local.vpc_cidr_block
}

output "availability_zones" {
  description = "List of availability zones"
  value       = local.azs
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc-eks.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc-eks.public_subnets
}

output "private_subnets_cidr" {
  description = "List of IDs of private subnets"
  value       = local.private_subnets_cidr
}

output "public_subnets_cidr" {
  description = "List of IDs of public subnets"
  value       = local.public_subnets_cidr
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc-eks.natgw_ids
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc-eks.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc-eks.private_route_table_ids
}
