#
# DB Security Group
#
resource "aws_security_group" "bb_mysql_db" {
  name        = "bb_mysql_db"
  description = "Binbash Reference MySQL DB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  tags        = local.tags
}
resource "aws_security_group_rule" "allow_mysql_port" {
  type      = "ingress"
  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"
  cidr_blocks = [
    data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
    data.terraform_remote_state.vpc-shared.outputs.vpc_cidr_block
  ]
  description       = "Allow PostgreSQL from DevStg and Shared"
  security_group_id = aws_security_group.bb_mysql_db.id
}

#
# Binbash Reference DB
#
module "bb_mysql_db" {
  source = "github.com/binbashar/terraform-aws-rds.git?ref=v3.1.0"

  # Instance settings
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html
  identifier        = "${var.project}-${var.environment}-binbash-mysql"
  engine            = "mysql"
  engine_version    = "8.0.21"
  instance_class    = "db.m5.large"
  allocated_storage = 100
  storage_encrypted = true
  multi_az          = true

  # Database credentials
  name     = "${var.project}_${replace(var.environment, "apps-", "")}_binbash_mysql"
  username = "administrator"
  #
  # Secret from secrets.enc
  #password = local.secrets.database_admin_password
  #
  # Secret from Hashicorp Vault
  password = data.vault_generic_secret.database_secrets.data["database_admin_password"]
  port     = "3306"

  # Backup and maintenance
  backup_retention_period = 14
  maintenance_window      = "Tue:03:00-Tue:06:00"
  backup_window           = "00:00-02:00"

  # Network settings
  subnet_ids             = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_security_group_ids = [aws_security_group.bb_mysql_db.id]

  # Mysql versions (param/option groups)
  family               = "mysql8.0"
  major_engine_version = "8.0"

  # Do not automatically upgrade
  auto_minor_version_upgrade = false

  # RDS Enhanced Monitoring
  # The interval, in seconds, between points when Enhanced Monitoring metrics
  # are collected for the DB instance.
  # To disable collecting Enhanced Monitoring metrics, specify 0.
  # The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60.
  monitoring_interval    = "0"
  monitoring_role_name   = "MyRDSMonitoringRoleMySQL"
  create_monitoring_role = false # true if Enhanced Monitoring needed

  # Tags + Bakup tag -> True
  tags = merge(local.tags, map("Backup", "True"))

  # Specifies whether any database modifications are applied immediately, or
  # during the next maintenance window
  apply_immediately = false

  # Database Deletion Protection
  deletion_protection = true
}
