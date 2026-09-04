module "mysql_db" {
  source = "github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v6.0.0"

  engine               = "mysql"
  engine_version       = "8.0.41"
  major_engine_version = "8.0"
}
