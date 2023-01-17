#
# Postgresql Provider Configuration
#
provider "postgresql" {
  host     = module.apps_devstg_aurora_postgresql.cluster_endpoint
  port     = module.apps_devstg_aurora_postgresql.cluster_port
  database = module.apps_devstg_aurora_postgresql.cluster_database_name
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

#   depends_on = [module.apps_devstg_aurora_postgresql]

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
#   database    = module.apps_devstg_aurora_postgresql.cluster_database_name
#   role        = postgresql_role.example_user.name
#   object_type = "database"
#   privileges = [
#     "CREATE",
#     "CONNECT",
#     "TEMPORARY"
#   ]
# }

# resource "postgresql_grant" "example_user_all_privileges_on_all_tables" {
#   database    = module.apps_devstg_aurora_postgresql.cluster_database_name
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
