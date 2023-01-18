#
# Postgresql Provider Configuration
#
provider "postgresql" {
  host     = module.bb_postgres_db.db_instance_endpoint
  port     = module.bb_postgres_db.db_instance_port
  database = module.bb_postgres_db.db_instance_name
  username = jsondecode(data.aws_secretsmanager_secret_version.administrator.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.administrator.secret_string)["password"]

  sslmode   = "require"
  superuser = false
}

###########################################################################
#
# Below are examples regarding user creation and permission granting.
# For more information on database resouces management head to
# https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs
#
###########################################################################

# #
# # DB User
# #
# resource "postgresql_role" "example_user" {
#   name     = "username" # Should be ideally provided from a secret, just as in the administrator's case
#   login    = true
#   password = "password" # Should be ideally provided from a secret, just as in the administrator's case

#   depends_on = [module.bb_postgres_db]

#   lifecycle {
#     ignore_changes = [
#       roles,
#     ]
#   }
# }

# #
# # DB Permissions
# #
# resource "postgresql_grant" "example_user_all_privileges_on_database" {
#   database    = module.bb_postgres_db.db_instance_name
#   role        = postgresql_role.example_user.name
#   object_type = "database"
#   privileges = [
#     "CREATE",
#     "CONNECT",
#     "TEMPORARY"
#   ]
# }

# resource "postgresql_grant" "example_user_all_privileges_on_all_tables" {
#   database    = module.bb_postgres_db.db_instance_name
#   role        = postgresql_role.example_user.name
#   schema      = "public"
#   object_type = "table"
#   privileges = [
#     "SELECT",
#     "INSERT",
#     "UPDATE",
#     "DELETE",
#     "TRUNCATE",
#     "REFERENCES",
#     "TRIGGER"
#   ]
# }
