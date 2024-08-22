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
  description = "CIDR of private subnets"
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

# output "security_group_arns" {
#   description = "List of security group ARNs"
#   value       = zipmap(
#     [
#       aws_security_group.https.name,
#       aws_security_group.egress_only.name,
#     ],
#     [
#       aws_security_group.https.arn,
#       aws_security_group.egress_only.arn,
#     ]
#   )
# }

# output "security_group_ids" {
#   description = "List of security group IDs"
#   value       = zipmap(
#     [
#       aws_security_group.https.name,
#       aws_security_group.egress_only.name,
#     ],
#     [
#       aws_security_group.https.id,
#       aws_security_group.egress_only.id,
#     ]
#   )
# }