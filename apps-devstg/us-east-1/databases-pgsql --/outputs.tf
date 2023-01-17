output "database_id" {
  description = "Database id"
  value       = module.bb_postgres_db.db_instance_id
}

output "database_name" {
  description = "Database name"
  value       = module.bb_postgres_db.db_instance_name
}

output "database_engine" {
  description = "Database engine"
  value       = module.bb_postgres_db.db_instance_engine
}

output "database_port" {
  description = "Database port"
  value       = module.bb_postgres_db.db_instance_port
}

output "database_username" {
  description = "Database username"
  value       = module.bb_postgres_db.db_instance_username
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = module.bb_postgres_db.db_instance_password
  sensitive   = true
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.bb_postgres_db.database_endpoint
}

output "database_security_group_id" {
  description = "Security group ID of the database"
  value       = aws_security_group.bb_postgres_db.id
}
