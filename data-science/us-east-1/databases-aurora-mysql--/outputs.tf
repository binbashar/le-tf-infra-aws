# aws_rds_cluster
output "cluster_id" {
  description = "The ID of the cluster"
  value       = module.demoapps.cluster_id
}

output "cluster_arn" {
  description = "The ID of the cluster"
  value       = module.demoapps.cluster_arn
}

output "cluster_resource_id" {
  description = "The Resource ID of the cluster"
  value       = module.demoapps.cluster_resource_id
}

output "cluster_endpoint" {
  description = "The cluster endpoint"
  value       = module.demoapps.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = module.demoapps.cluster_reader_endpoint
}

output "cluster_database_name" {
  description = "Name for an automatically created database on cluster creation"
  value       = module.demoapps.cluster_database_name
}

output "cluster_master_password" {
  description = "The master password"
  value       = module.demoapps.cluster_master_password
  sensitive   = true
}

output "cluster_port" {
  description = "The port"
  value       = module.demoapps.cluster_port
}

output "cluster_master_username" {
  description = "The master username"
  value       = module.demoapps.cluster_master_username
  sensitive   = true
}

output "cluster_instances" {
  description = "contains a map of all instances created and their attributes"
  value       = module.demoapps.cluster_instances
}

# aws_security_group
output "security_group_id" {
  description = "The security group ID of the cluster"
  value       = module.demoapps.security_group_id
}

output "demoapps_sockshop_username" {
  description = "Sock-Shop DemoApp Username"
  value       = mysql_user.sockshop.user
}

output "demoapps_sockshop_password" {
  description = "Sock-Shop DemoApp Password"
  value       = random_password.sockhsop.result
  sensitive   = true
}

output "demoapps_sockshop_database_name" {
  description = "Sock-Shop DemoApp Database Name"
  value       = mysql_database.sockshop.name
}
