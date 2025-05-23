resource "mysql_database" "sockshop" {
  name       = "socksdb"
  depends_on = [module.demoapps]
}

resource "random_password" "sockhsop" {
  length           = 30
  special          = false
  min_lower        = 8
  min_upper        = 8
  min_numeric      = 8
  min_special      = 0
  override_special = ""
}

resource "mysql_user" "sockshop" {
  user               = "catalogue_user"
  host               = "%"
  plaintext_password = random_password.sockhsop.result
  depends_on         = [module.demoapps]
}

resource "mysql_grant" "sockshop" {
  user       = mysql_user.sockshop.user
  host       = mysql_user.sockshop.host
  database   = mysql_database.sockshop.name
  privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "REFERENCES", "DROP"]
}

resource "mysql_grant" "sockshop_global" {
  user       = mysql_user.sockshop.user
  host       = mysql_user.sockshop.host
  privileges = ["REPLICATION SLAVE", "REPLICATION CLIENT"]
  database   = "*" # Use * for global privileges
}
