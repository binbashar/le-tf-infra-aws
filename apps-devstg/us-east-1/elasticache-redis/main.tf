#==============================================================
# Check out the README.md file for implementation details.
#==============================================================
module "elasticache_redis" {
  source = "github.com/binbashar/terraform-aws-elasticache-redis.git?ref=v1.10.0"

  #-------------------------------
  # Cluster
  #-------------------------------
  name                       = "${var.project}-${var.environment}-redis"
  description                = "${var.project}-${var.environment}-redis"
  cluster_size               = var.cluster_size
  instance_type              = var.instance_type
  apply_immediately          = true
  automatic_failover_enabled = false

  #-------------------------------
  # VPC
  #-------------------------------
  vpc_id                          = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets                         = data.terraform_remote_state.vpc.outputs.private_subnets
  availability_zones              = data.terraform_remote_state.vpc.outputs.availability_zones
  allowed_security_groups         = []
  additional_security_group_rules = []
  allow_all_egress                = false

  #-------------------------------
  # Engine
  #-------------------------------
  engine_version = var.engine_version
  family         = var.family
  parameter = [
    {
      name  = "notify-keyspace-events"
      value = "lK"
    }
  ]

  #-------------------------------
  # Security
  #-------------------------------
  auth_token                 = data.aws_secretsmanager_secret_version.auth_token.secret_string
  auth_token_update_strategy = "SET"
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
}
