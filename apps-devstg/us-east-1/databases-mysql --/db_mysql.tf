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
  source = "github.com/binbashar/terraform-aws-rds.git?ref=v5.9.0"

  # Instance settings
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html
  identifier        = "${var.project}-${var.environment}-binbash-mysql"
  engine            = "mysql"
  engine_version    = "8.0.41"
  instance_class    = "db.m6g.large"
  allocated_storage = 100
  storage_encrypted = true
  multi_az          = false

  # Database credentials
  db_name  = "${var.project}_${replace(var.environment, "apps-", "")}_binbash_mysql"
  username = jsondecode(data.aws_secretsmanager_secret_version.database_secrets.secret_string).username
  password = jsondecode(data.aws_secretsmanager_secret_version.database_secrets.secret_string).password
  port     = "3306"

  # Backup and maintenance
  backup_retention_period = 14
  maintenance_window      = "Tue:03:00-Tue:06:00"
  backup_window           = "00:00-02:00"

  # Network settings
  create_db_subnet_group = true
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
  tags = merge(local.tags, tomap({ Backup = "True" }))

  # Specifies whether any database modifications are applied immediately, or
  # during the next maintenance window
  apply_immediately = true

  # Database Deletion Protection
  deletion_protection = false
}
