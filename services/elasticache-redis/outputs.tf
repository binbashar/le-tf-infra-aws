output "endpoint" {
  value       = module.elasticache_redis.endpoint
  description = "Redis primary, configuration or serverless endpoint, whichever is appropriate for the given configuration"
}

output "port" {
  description = "Redis port"
  value       = module.elasticache_redis.port
}
