# aws_rds_cluster
output "this_rds_cluster_id" {
  description = "The ID of the cluster"
  value       = module.demoapps.this_rds_cluster_id
}

output "this_rds_cluster_resource_id" {
  description = "The Resource ID of the cluster"
  value       = module.demoapps.this_rds_cluster_resource_id
}

output "this_rds_cluster_endpoint" {
  description = "The cluster endpoint"
  value       = module.demoapps.this_rds_cluster_endpoint
}

output "this_rds_cluster_reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = module.demoapps.this_rds_cluster_reader_endpoint
}

output "this_rds_cluster_database_name" {
  description = "Name for an automatically created database on cluster creation"
  value       = module.demoapps.this_rds_cluster_database_name
}

output "this_rds_cluster_master_password" {
  description = "The master password"
  value       = module.demoapps.this_rds_cluster_master_password
  sensitive   = true
}

output "this_rds_cluster_port" {
  description = "The port"
  value       = module.demoapps.this_rds_cluster_port
}

output "this_rds_cluster_master_username" {
  description = "The master username"
  value       = module.demoapps.this_rds_cluster_master_username
}

# aws_rds_cluster_instance
output "this_rds_cluster_instance_endpoints" {
  description = "A list of all cluster instance endpoints"
  value       = module.demoapps.this_rds_cluster_instance_endpoints
}

output "this_rds_cluster_instance_ids" {
  description = "A list of all cluster instance ids"
  value       = module.demoapps.this_rds_cluster_instance_ids
}

# aws_security_group
output "this_security_group_id" {
  description = "The security group ID of the cluster"
  value       = module.demoapps.this_security_group_id
}

output "demoapps_sockshop_username" {
  description = "Sock-Shop DemoApp Username"
  value       = mysql_user.sockshop.user
}

output "demoapps_sockshop_password" {
  description = "Sock-Shop DemoApp Password"
  value       = mysql_user.sockshop.password
  sensitive   = true
}

output "demoapps_sockshop_database_name" {
  description = "Sock-Shop DemoApp Database Name"
  value       = mysql_database.sockshop.name
}
