# aws_rds_cluster
output "cluster_id" {
  description = "The ID of the cluster"
  value       = module.apps_devstg_aurora_postgresql.cluster_id
}

output "cluster_arn" {
  description = "The ID of the cluster"
  value       = module.apps_devstg_aurora_postgresql.cluster_arn
}

output "cluster_resource_id" {
  description = "The Resource ID of the cluster"
  value       = module.apps_devstg_aurora_postgresql.cluster_resource_id
}

output "cluster_endpoint" {
  description = "The cluster endpoint"
  value       = module.apps_devstg_aurora_postgresql.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = module.apps_devstg_aurora_postgresql.cluster_reader_endpoint
}

output "cluster_database_name" {
  description = "Name for an automatically created database on cluster creation"
  value       = module.apps_devstg_aurora_postgresql.cluster_database_name
}

output "cluster_engine" {
  description = "The cluster engine"
  value       = local.engine
}

output "cluster_master_password" {
  description = "The master password"
  value       = module.apps_devstg_aurora_postgresql.cluster_master_password
  sensitive   = true
}

output "cluster_port" {
  description = "The port"
  value       = module.apps_devstg_aurora_postgresql.cluster_port
}

output "cluster_master_username" {
  description = "The master username"
  value       = module.apps_devstg_aurora_postgresql.cluster_master_username
  sensitive   = true
}

output "cluster_instances" {
  description = "contains a map of all instances created and their attributes"
  value       = module.apps_devstg_aurora_postgresql.cluster_instances
}

output "security_group_id" {
  description = "The security group ID of the cluster"
  value       = module.apps_devstg_aurora_postgresql.security_group_id
}
