module "elasticache" {
  source = "github.com/binbashar/terraform-aws-elasticache.git?ref=v1.6.0"

  replication_group_id = "example-redis-cluster"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t3.small"
  # Cluster mode
  cluster_mode_enabled       = false #add var -> if false : single node instance.
  automatic_failover_enabled = false #depends on multiz [dev]
  multi_az_enabled           = false #depends on failover [dev]
  snapshot_retention_limit   = 0     #disable the persistence
  snapshot_window            = null  #disable the persistence

  at_rest_encryption_enabled = true #do i create a kms for this?
  #kms_key_id = optional. depends if at_rest_encryption_enabled is set to true. otherwise will use default.

  transit_encryption_enabled = true
  auth_token                 = "" #depends if transit_encryption_enabled is set to true. Password used to access a password protected server. 
  #TODO: take it from secrets manager.
  #auth_token_update_strategy: research.

  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately  = true


  # Security group
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  security_group_rules = {
    ingress_vpc = {
      # Default type is `ingress`
      # Default port is based on the default engine port
      description = "VPC traffic"
      cidr_ipv4   = "0.0.0.0/0"
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
/*
output "v1" {
    value = data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip
  
}

output "v2" {
  value = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
}*/

resource "aws_security_group_rule" "elasticache_egress_custom" {
  type              = "egress"
  from_port         = 0                                    # customize as needed
  to_port           = 0                                    # same or range
  protocol          = -1                                   # or "-1" for all
  security_group_id = module.elasticache.security_group_id # module's SG
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound to internal services"
}
