#
# DB Security Group
#
resource "aws_security_group" "bb_postgres_db" {
  name        = "bb_postgres_db"
  description = "Binbash Reference Postgres DB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  tags        = local.tags
}
resource "aws_security_group_rule" "allow_postgresql_port" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  cidr_blocks = [
    data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
    data.terraform_remote_state.vpc-shared.outputs.vpc_cidr_block
  ]
  description       = "Allow PostgreSQL from DevStg and Shared"
  security_group_id = aws_security_group.bb_postgres_db.id
}

#
# Binbash Reference DB
#
module "bb_postgres_db" {
  source = "git::git@github.com:binbashar/terraform-aws-rds.git?ref=v2.13.0"

  # Instance settings
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
  identifier        = "${var.project}-${var.environment}-binbash-postgres"
  engine            = "postgres"
  engine_version    = "11.5"
  instance_class    = "db.m5.large"
  allocated_storage = 100
  storage_encrypted = true
  multi_az          = true

  # Database credentials
  name     = "${var.project}_${replace(var.environment, "apps-", "")}_binbash_postgres"
  username = "administrator"
  password = local.secrets.database_admin_password
  port     = "5432"

  # Backup and maintenance
  backup_retention_period = 14
  maintenance_window      = "Tue:03:00-Tue:06:00"
  backup_window           = "00:00-02:00"

  # Network settings
  subnet_ids             = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_security_group_ids = [aws_security_group.bb_postgres_db.id]

  # Postgres versions (param/option groups)
  family               = "postgres11"
  major_engine_version = "11"

  # Do not automatically upgrade
  auto_minor_version_upgrade = false

  # RDS Enhanced Monitoring
  # The interval, in seconds, between points when Enhanced Monitoring metrics
  # are collected for the DB instance.
  # To disable collecting Enhanced Monitoring metrics, specify 0.
  # The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60.
  monitoring_interval    = "0"
  monitoring_role_name   = "MyRDSMonitoringRolePostgres"
  create_monitoring_role = false # true if Enhanced Monitoring needed

  # Tags + Bakup tag -> True
  tags = "${merge(local.tags, map("Backup", "True"))}"

  # Specifies whether any database modifications are applied immediately, or
  # during the next maintenance window
  apply_immediately = false

  # Database Deletion Protection
  deletion_protection = true
}
