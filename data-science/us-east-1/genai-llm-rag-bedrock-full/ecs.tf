################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "github.com/binbashar/terraform-aws-ecs.git//modules/cluster?ref=v5.11.4"

  cluster_name = "${local.name}-cluster"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  tags = local.tags
}

################################################################################
# Service
################################################################################

module "ecs_service" {
  source = "github.com/binbashar/terraform-aws-ecs.git//modules/service?ref=v5.11.4"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  task_exec_iam_role_name            = "${local.name}-task-exec-role"
  tasks_iam_role_name                = "${local.name}-task-role"
  tasks_iam_role_use_name_prefix     = false
  task_exec_iam_role_use_name_prefix = false
  task_exec_ssm_param_arns           = []

  tasks_iam_role_statements = local.iam_role_statements

  # Autoscaling
  enable_autoscaling = false

  container_definitions = local.container_definitions
  launch_type           = "FARGATE"

  # Enables ECS Exec
  enable_execute_command = true

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["default"].arn
      container_name   = "demo"
      container_port   = 8080
    }
  }

  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets


  # ECS Services are only reached by ALB
  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}
