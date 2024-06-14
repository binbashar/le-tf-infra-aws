#
# Check for available NAT Gateway in VPC
#
data "aws_nat_gateways" "natgtw" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  filter {
    name   = "state"
    values = ["available"]
  }

  lifecycle {
    postcondition {
      condition     = length(self.ids) != 0
      error_message = "Make sure a NAT Gateway is up before deploying the ECS cluster, otherwise the tasks will not be able to reach the internet."
    }
  }
}

#
# Apps-DevStg ECS Demoapps Cluster
#
module "apps_devstg_ecs_cluster" {
  source = "github.com/binbashar/terraform-aws-ecs.git?ref=v5.11.1"

  cluster_name = "${local.name}-cluster"

  # Capcity providers definition
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = { for service_name, service_values in local.services :
    # Service definition
    service_name => {
      # Service resources
      cpu    = service_values.cpu
      memory = service_values.memory

      # Containers definiton
      container_definitions = { for container_name, container_values in service_values.containers :
        container_name => {
          cpu    = container_values.cpu
          memory = container_values.memory

          # Container image
          image = "${container_values.image}:${container_values.version}"

          # Environment variables
          environment = [for env_var, env_value in try(container_values.environment, {}) :
            {
              name  = env_var,
              value = env_value
            }
          ]

          # Network
          port_mappings = [for port_name, port_number in try(container_values.ports, {}) :
            {
              name          = port_name,
              containerPort = port_number,
              hostPort      = port_number,
              protocol      = "tcp"
            }
          ]
        }
      }

      # Task IAM Roles and policies
      tasks_iam_role_name = "${service_name}-ecr-task"
      # Service IAM Roles and policies
      task_exec_iam_role_name = "${service_name}-ecr-exec"

      # Networking
      subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
      security_group_rules = merge(
        { for container_name, container_values in local.routing[service_name] :
          "ingress_${service_name}_${replace(container_name, "-", "_")}_${container_values.port}" => {
            type                     = "ingress"
            from_port                = container_values.port
            to_port                  = container_values.port
            protocol                 = "tcp"
            source_security_group_id = aws_security_group.apps_devstg_alb_ecs_demoapps.id
          }
        },
        {
          egress_all = {
            type        = "egress"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      )

      # Target group assignment
      load_balancer = { for container_name, container_values in local.routing[service_name] :
        container_name => {
          target_group_arn = module.apps_devstg_alb_ecs_demoapps.target_groups[container_name].arn
          container_name   = container_name
          container_port   = container_values.port
        }
      }
    }
  }

  depends_on = [data.aws_nat_gateways.natgtw]

  tags = local.tags
}
