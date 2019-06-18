# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = "${module.vpc.vpc_id}"
}

output "vpc_name" {
  description = "VPC Name"
  value       = "${local.vpc_name}"
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = "${local.vpc_cidr_block}"
}

output "availability_zones" {
  description = "List of availability zones"
  value       = ["${local.azs}"]
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.vpc.private_subnets}"]
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = ["${module.vpc.public_subnets}"]
}

output "private_subnets_cidr" {
  description = "List of IDs of private subnets"
  value       = ["${local.private_subnets}"]
}

output "public_subnets_cidr" {
  description = "List of IDs of public subnets"
  value       = ["${local.public_subnets}"]
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = ["${module.vpc.natgw_ids}"]
}

output "aws_public_zone_id" {
  description = "ID public DNS aws zone"
  value       = ["${aws_route53_zone.aws_public_hosted_zone_1.id}"]
}

output "aws_internal_zone_id" {
  description = "ID private DNSaws"
  value       = ["${aws_route53_zone.aws_private_hosted_zone_1.id}"]
}
