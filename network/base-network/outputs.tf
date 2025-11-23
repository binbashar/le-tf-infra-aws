#===========================================#
# VPC Outputs
# Organized outputs for the VPC module configuration
#===========================================#

# VPC Core Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances launched into the VPC"
  value       = module.vpc.vpc_instance_tenancy
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.vpc.vpc_enable_dns_hostnames
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.vpc.vpc_enable_dns_support
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.azs
}

# Internet Gateway
output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

# NAT Gateway
output "nat_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

# Subnets - Public
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "public_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of public subnets in an IPv6 enabled VPC"
  value       = module.vpc.public_subnets_ipv6_cidr_blocks
}

# Subnets - Private
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "private_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of private subnets in an IPv6 enabled VPC"
  value       = module.vpc.private_subnets_ipv6_cidr_blocks
}

# Subnets - Database
output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = module.vpc.database_subnet_arns
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}

output "database_subnet_group" {
  description = "ID of the database subnet group"
  value       = module.vpc.database_subnet_group
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.vpc.database_subnet_group_name
}

# Subnets - Elasticache
output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.vpc.elasticache_subnets
}

output "elasticache_subnet_arns" {
  description = "List of ARNs of elasticache subnets"
  value       = module.vpc.elasticache_subnet_arns
}

output "elasticache_subnet_group" {
  description = "ID of the elasticache subnet group"
  value       = try(module.vpc.elasticache_subnet_group, null)
}

output "elasticache_subnet_group_name" {
  description = "Name of the elasticache subnet group"
  value       = try(module.vpc.elasticache_subnet_group_name, null)
}

# Subnets - Redshift
output "redshift_subnets" {
  description = "List of IDs of redshift subnets"
  value       = module.vpc.redshift_subnets
}

output "redshift_subnet_arns" {
  description = "List of ARNs of redshift subnets"
  value       = module.vpc.redshift_subnet_arns
}

output "redshift_subnet_group" {
  description = "ID of the redshift subnet group"
  value       = try(module.vpc.redshift_subnet_group, null)
}

output "redshift_subnet_group_name" {
  description = "Name of the redshift subnet group"
  value       = try(module.vpc.redshift_subnet_group_name, null)
}

# Subnets - Intra
output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = module.vpc.intra_subnets
}

output "intra_subnet_arns" {
  description = "List of ARNs of intra subnets"
  value       = module.vpc.intra_subnet_arns
}

output "intra_subnets_cidr_blocks" {
  description = "List of cidr_blocks of intra subnets"
  value       = module.vpc.intra_subnets_cidr_blocks
}

# Route Tables
output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = module.vpc.database_route_table_ids
}

output "intra_route_table_ids" {
  description = "List of IDs of intra route tables"
  value       = module.vpc.intra_route_table_ids
}

# Network ACLs
output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = module.vpc.public_network_acl_id
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = module.vpc.private_network_acl_id
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = try(module.vpc.database_network_acl_id, null)
}

output "intra_network_acl_id" {
  description = "ID of the intra network ACL"
  value       = try(module.vpc.intra_network_acl_id, null)
}

# Subnets - Outpost
output "outpost_subnets" {
  description = "List of IDs of outpost subnets"
  value       = module.vpc.outpost_subnets
}

output "outpost_subnet_arns" {
  description = "List of ARNs of outpost subnets"
  value       = module.vpc.outpost_subnet_arns
}

output "outpost_subnets_cidr_blocks" {
  description = "List of cidr_blocks of outpost subnets"
  value       = module.vpc.outpost_subnets_cidr_blocks
}

output "outpost_network_acl_id" {
  description = "ID of the outpost network ACL"
  value       = try(module.vpc.outpost_network_acl_id, null)
}

# VPN Gateway
output "vgw_id" {
  description = "ID of the VPN Gateway"
  value       = module.vpc.vgw_id
}

# Customer Gateway
output "cgw_ids" {
  description = "List of IDs of Customer Gateway"
  value       = module.vpc.cgw_ids
}

output "cgw_arns" {
  description = "List of ARNs of Customer Gateway"
  value       = module.vpc.cgw_arns
}

# VPC Flow Logs
output "vpc_flow_log_id" {
  description = "The ID of the Flow Log"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "vpc_flow_log_destination_type" {
  description = "The type of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_type
}

# DHCP Options Set
output "dhcp_options_id" {
  description = "The ID of the DHCP Options Set"
  value       = module.vpc.dhcp_options_id
}

# Default VPC
output "default_vpc_id" {
  description = "The ID of the Default VPC"
  value       = module.vpc.default_vpc_id
}

output "default_vpc_cidr_block" {
  description = "The CIDR block of the Default VPC"
  value       = module.vpc.default_vpc_cidr_block
}

output "default_vpc_default_security_group_id" {
  description = "The ID of the security group created by default on Default VPC creation"
  value       = module.vpc.default_vpc_default_security_group_id
}

output "default_vpc_default_network_acl_id" {
  description = "The ID of the default network ACL of the Default VPC"
  value       = module.vpc.default_vpc_default_network_acl_id
}

output "default_vpc_default_route_table_id" {
  description = "The ID of the default route table of the Default VPC"
  value       = module.vpc.default_vpc_default_route_table_id
}

# Configuration Summary
output "vpc_config_summary" {
  description = "Summary of VPC configuration"
  value = {
    version     = var.vpc_config.version
    region      = var.vpc_config.region
    name        = var.vpc_config.vpc.metadata.name
    environment = var.vpc_config.vpc.metadata.environment
    cidr        = var.vpc_config.vpc.networking.cidrBlock
    availability_zones = distinct(concat(
      [for s in var.vpc_config.vpc.networking.subnets.public : s.availabilityZone],
      [for s in var.vpc_config.vpc.networking.subnets.private : s.availabilityZone],
      [for s in var.vpc_config.vpc.networking.subnets.database : s.availabilityZone],
      [for s in var.vpc_config.vpc.networking.subnets.redshift : s.availabilityZone],
      [for s in var.vpc_config.vpc.networking.subnets.elasticache : s.availabilityZone],
      [for s in var.vpc_config.vpc.networking.subnets.intra : s.availabilityZone],
      [for s in var.vpc_config.vpc.networking.subnets.outpost : s.availabilityZone]
    ))
    enable_nat_gateway = var.vpc_config.vpc.networking.natGateways.enabled
    single_nat_gateway = var.vpc_config.vpc.networking.natGateways.single
    enable_flow_logs   = var.vpc_config.vpc.monitoring.flowLogs.enabled
    multi_az           = var.vpc_config.vpc.availability.multiAz
  }
}
