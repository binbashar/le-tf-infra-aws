#
# NOTE: Before deploying make sure the required secret is created via apps-devstg/us-east-1/secrets-manager layer
#

#
# DB Administrator secret
#
data "aws_secretsmanager_secret_version" "administrator" {
  secret_id = data.terraform_remote_state.secrets.outputs.secret_ids["/aurora-mysql/administrator"]
}

module "demoapps" {
  source = "github.com/binbashar/terraform-aws-rds-aurora.git?ref=v7.7.1"

  # General settings
  name           = "${var.project}-${var.environment}-binbash-aurora-mysql"
  engine         = "aurora-mysql"
  engine_mode    = "provisioned"
  engine_version = "5.7"

  # Initial database and credentials
  database_name          = "demoapps"
  master_username        = jsondecode(data.aws_secretsmanager_secret_version.administrator.secret_string)["username"]
  master_password        = jsondecode(data.aws_secretsmanager_secret_version.administrator.secret_string)["password"]
  create_random_password = false

  # VPC and Subnets
  vpc_id  = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # Instance type and desired instances
  instance_class = "db.t3.small"
  instances = {
    one = {}
  }


  # Autoscaling settings
  autoscaling_enabled = false
  # autoscaling_min_capacity        = 1
  # autoscaling_max_capacity         = 3
  # autoscaling_target_cpu         = 85
  # autoscaling_target_connections = 200

  # Storage encrypted as default
  storage_encrypted = true

  # Determines whether or not any DB modifications are applied immediately, or during the maintenance window
  # Only 'true' in test environments
  apply_immediately = true

  # Automatic backup settings
  backup_retention_period = 1
  preferred_backup_window = "14:00-15:00"

  # This avoid a snapshot before destroy the cluster
  skip_final_snapshot = true

  # Monitoring settings
  # enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # Database parameters: you can specify your own if you must
  # db_parameter_group_name         = aws_db_parameter_group.aurora_db_57_parameter_group.id
  # db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_57_cluster_parameter_group.id
  create_db_cluster_parameter_group = true
  db_cluster_parameter_group_family = "aurora-mysql5.7"
  db_cluster_parameter_group_parameters = [{
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }]

  # If true, must add policy to iam auth (user or role)
  iam_database_authentication_enabled = false

  # Security group settings
  create_security_group = true
  allowed_cidr_blocks = [
    "0.0.0.0/0",
    data.terraform_remote_state.shared_vpc.outputs.vpc_cidr_block
  ]

  tags = local.tags
}
