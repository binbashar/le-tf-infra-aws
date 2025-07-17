module "elasticache" {
  source = "github.com/binbashar/terraform-aws-elasticache.git?ref=v1.6.0"

  replication_group_id = local.name

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type
  # Cluster mode
  cluster_mode_enabled       = var.cluster_mode_enabled && !var.single_instance_mode_enabled
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = var.snapshot_window

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  #kms_key_id = optional. depends if at_rest_encryption_enabled is set to true. otherwise will use default.

  transit_encryption_enabled = true
  auth_token                 = "" #depends if transit_encryption_enabled is set to true. Password used to access a password protected server. 
  #TODO: take it from secrets manager.
  #auth_token_update_strategy: research.

  maintenance_window = var.maintenance_window
  apply_immediately  = var.apply_immediately


  # Security group
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  security_group_rules = {
    ingress_vpc = {
      # Default type is `ingress`
      # Default port is based on the default engine port
      description = "VPC traffic"
      cidr_ipv4   = "0.0.0.0/0" #TODO: fix this
    }
    egress_vpc = {
      type      = "egress"
      from_port = 0  # customize as needed
      to_port   = 0  # same or range
      #protocol  = -1 # or "-1" for all
      cidr_ipv4   = "0.0.0.0/0" #TODO: fix this
    }
  }

  # Subnet Group
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters             = []

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
output "name" {
  value = var.cluster_mode_enabled || !var.single_instance_mode_enabled
}
/*
output "v1" {
    value = data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip
  
}

output "v2" {
  value = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
}*/
/*
#TODO: FIX ports and cidrs
resource "aws_security_group_rule" "elasticache_egress_custom" {
  type              = "egress"
  from_port         = 0                                    # customize as needed
  to_port           = 0                                    # same or range
  protocol          = -1                                   # or "-1" for all
  security_group_id = module.elasticache.security_group_id # module's SG
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound to internal services"
}*/
