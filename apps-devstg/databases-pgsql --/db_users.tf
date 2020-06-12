# provider "postgresql" {
#   # Here you can use the instance IP instead if you find DNS issues
#   host            = module.bb_postgres_db.this_db_instance_endpoint
#   port            = 5432
#   database        = "postgres"
#   username        = "administrator"
#   password        = local.secrets.database_admin_password
# 
#   # This will skip the auto-detect version during "plan" but if there is a dns
#   # resolution issue, it will still show up during "apply"
#   # expected_version = "11.5"
# 
#   # This line below is necessary when you use AWS RDS instances as they don't
#   # grant you superuser privileges but a user with the rds_superuser role which
#   # has not the same kind of permissions
#   superuser = false
# 
#   sslmode         = "disable"
#   connect_timeout = 15
# }

# resource "postgresql_database" "sample_db" {
#   name              = "sample_db"
#   # owner             = "administrator"
#   allow_connections = true
# }
# 
# resource "postgresql_role" "sample_role" {
#   name     = "sample_role"
#   login    = true
#   password = "abcdef123456"
# }