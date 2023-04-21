output "bb_reference_db_id" {
  description = "Postgres reference db id"
  value       = module.bb_mysql_db.db_instance_id
}
