#
# NOTE: Before deploying make sure the required secret is created via apps-devstg/us-east-1/secrets-manager layer
#

#
# DB Administrator secret
#
data "aws_secretsmanager_secret_version" "administrator" {
  secret_id = data.terraform_remote_state.secrets.outputs.secret_ids["/aurora-pgsql/administrator"]
}

#
# Apps DevStg Aurora DB
#
module "apps_devstg_aurora_postgresql" {
  source = "github.com/binbashar/terraform-aws-rds-aurora.git?ref=v7.5.1"

  # General settings
  name           = local.name
  engine         = local.engine
  engine_mode    = "provisioned"
  engine_version = "14.8"

  # Initial database and credentials
  database_name          = "demoapps"
  master_username        = jsondecode(data.aws_secretsmanager_secret_version.administrator.secret_string)["username"]
  master_password        = jsondecode(data.aws_secretsmanager_secret_version.administrator.secret_string)["password"]
  create_random_password = false

  # VPC and Subnets
  vpc_id  = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # Instance type and desired instances
  instance_class = "db.t3.medium"
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
  #db_parameter_group_name         = aws_db_parameter_group.aurora_db_57_parameter_group.id
  #db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_57_cluster_parameter_group.id
  create_db_cluster_parameter_group = true
  db_cluster_parameter_group_family = "aurora-postgresql14"
  db_cluster_parameter_group_parameters = [{
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }]

  # If true, must add policy to iam auth (user or role)
  iam_database_authentication_enabled = false

  # Security group settings
  create_security_group = true
  allowed_cidr_blocks = [
    data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
    data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block,
    data.terraform_remote_state.datascience-vpc.outputs.vpc_cidr_block
  ]

  tags = local.tags
}
