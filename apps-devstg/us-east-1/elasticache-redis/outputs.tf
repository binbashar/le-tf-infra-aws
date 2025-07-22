output "replication_group_primary_endpoint_address" {
  value       = module.elasticache.replication_group_primary_endpoint_address
  description = "Address of the endpoint for the primary node in the replication group, if the cluster mode is disabled"
}
output "replication_group_configuration_endpoint_address" {
  value       = module.elasticache.replication_group_configuration_endpoint_address
  description = "Address of the replication group configuration endpoint when cluster mode is enabled"
}

output "cluster_address" {
  value       = try(module.elasticache.cluster_cache_nodes[0].address,"")
  description = "Address of the node endpoint when single node instance is enabled"
}

output "port" {
  description = "Address of the replication group configuration endpoint when cluster mode is enabled"
  value       = var.port
}
