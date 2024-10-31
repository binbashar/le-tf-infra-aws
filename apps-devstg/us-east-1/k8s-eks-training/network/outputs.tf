# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
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
  value       = module.vpc.vpc_name
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  description = "List of availability zones"
  value       = module.vpc.azs
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
  value       = module.vpc.private_subnets_cidr
}

output "public_subnets_cidr" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets_cidr
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

output "peerings_created_for" {
  value = {for k, v in module.vpc.peerings_created_for : k => v}
}

output "z_note_on_vpn" {
  value = <<EOF
  # ##########################################################
  Remember, if you have set a VPN, add the current CIDR (${module.vpc.vpc_cidr_block}) to its networks
  # ##########################################################
EOF
}
