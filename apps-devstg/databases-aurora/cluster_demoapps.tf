data "vault_generic_secret" "devstg_database_aurora" {
  path = "secrets/le-tf-infra-aws/apps-devstg/databases-aurora"
}

module "demoapps" {
  source = "github.com/binbashar/terraform-aws-rds-aurora.git?ref=v3.7.0"

  # General settings
  name           = "${var.project}-${var.environment}-binbash-aurora-mysql"
  engine         = "aurora-mysql"
  engine_mode    = "provisioned"
  engine_version = "5.7.12"

  # Initial database and credentials
  database_name          = "demoapps"
  username               = "admin"
  password               = data.vault_generic_secret.devstg_database_aurora.data["db_demoapps_admin_password"]
  create_random_password = false

  # VPC and Subnets
  vpc_id  = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # Instance type and desired instances
  instance_type = "db.t3.small"
  replica_count = 1

  # Autoscaling settings
  replica_scale_enabled       = false
  # replica_scale_min         = 1
  # replica_scale_max         = 3
  # replica_scale_cpu         = 85
  # replica_scale_connections = 200

  # Storage encrypted as default
  storage_encrypted = true

  # Determines whether or not any DB modifications are applied immediately, or during the maintenance window
  # Only 'true' in test environments
  apply_immediately = true

  # Automatic backup settings
  backup_retention_period = 7

  # This avoid a snapshot before destroy the cluster
  skip_final_snapshot = true

  # Monitoring settings
  # enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # Database parameters: you can specify your own if you must
  # db_parameter_group_name         = aws_db_parameter_group.aurora_db_57_parameter_group.id
  # db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_57_cluster_parameter_group.id

  # If true, must add policy to iam auth (user or role)
  iam_database_authentication_enabled = false

  # Security group settings
  create_security_group = true
  allowed_cidr_blocks   = [
    data.terraform_remote_state.eks_vpc.outputs.vpc_cidr_block,
    data.terraform_remote_state.shared_vpc.outputs.vpc_cidr_block
  ]

  tags = local.tags
}
