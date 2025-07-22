module "elasticache" {
  source = "github.com/binbashar/terraform-aws-elasticache.git?ref=v1.6.0"

  create_replication_group = var.cluster_mode_enabled
  replication_group_id     = var.cluster_mode_enabled ? local.name : null

  create_cluster = var.single_instance_mode_enabled
  cluster_id     = var.single_instance_mode_enabled ? local.name : ""

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type

  # Cluster mode
  cluster_mode_enabled       = var.cluster_mode_enabled && !var.single_instance_mode_enabled
  automatic_failover_enabled = var.cluster_mode_enabled ? var.automatic_failover_enabled : false
  multi_az_enabled           = var.cluster_mode_enabled ? var.multi_az_enabled : false
  num_node_groups            = var.cluster_mode_enabled ? var.num_node_groups : 0
  replicas_per_node_group    = var.cluster_mode_enabled ? var.replicas_per_node_group : 0

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  #kms_key_id = optional. depends if at_rest_encryption_enabled is set to true. otherwise will use default.

  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = data.aws_secretsmanager_secret_version.auth_token.secret_string
  #auth_token_update_strategy: research.

  maintenance_window = var.maintenance_window
  apply_immediately  = var.apply_immediately


  # Security group
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  security_group_rules = {
    ingress_vpc = {
      #default type is ingress.
      from_port   = var.port
      to_port     = var.port
      ip_protocol = "tcp"
      description = "VPC traffic"
      cidr_ipv4   = data.terraform_remote_state.shared_vpc.outputs.vpc_cidr_block
    }
    egress_vpc = {
      type        = "egress"
      from_port   = var.port
      to_port     = var.port
      ip_protocol = "tcp"
      description = "VPC traffic"
      cidr_ipv4   = data.terraform_remote_state.shared_vpc.outputs.vpc_cidr_block
    }
  }

  # Subnet Group
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters             = var.parameters

}
