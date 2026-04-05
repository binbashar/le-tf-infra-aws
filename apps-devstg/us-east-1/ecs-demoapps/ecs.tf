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
  source = "github.com/binbashar/terraform-aws-ecs.git?ref=v6.7.0"

  cluster_name = "${local.name}-cluster"

  # Default capacity provider strategy
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 100
      base   = 1
    }
  }

  services = { for service_name, service_values in local.services :
    # Service definition
    service_name => {
      # Service resources
      cpu    = service_values.cpu
      memory = service_values.memory

      # Ephemeral storage configuration (Fargate task-level storage)
      # Default is 20 GiB if not specified, can be increased up to 200 GiB
      # Module expects an object with size_in_gib field
      ephemeral_storage = try(service_values.ephemeral_storage_size_in_gib, null) != null ? {
        size_in_gib = service_values.ephemeral_storage_size_in_gib
      } : null

      # Volumes configuration
      # tmpfs: Only name required (Fargate auto-provisions in-memory storage)
      # EFS: Requires efs_volume_configuration with file_system_id
      volume = try(service_values.volumes, null) != null ? {
        for volume_name, volume_config in service_values.volumes :
        volume_name => {
          name                                         = volume_name
          configure_at_launch                          = null
          docker_volume_configuration                  = null
          host_path                                    = null
          fsx_windows_file_server_volume_configuration = null
          efs_volume_configuration = volume_config.type == "efs" ? {
            file_system_id          = volume_config.file_system_id
            root_directory          = null
            transit_encryption      = null
            transit_encryption_port = null
            authorization_config    = null
          } : null
        }
      } : null

      # Deployment configuration
      deployment_configuration = {
        strategy             = var.ecs_deployment_type
        bake_time_in_minutes = var.ecs_deployment_type == "BLUE_GREEN" ? 5 : null
      }

      # Deployment percentage settings (at service level)
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = var.ecs_deployment_type == "BLUE_GREEN" ? 100 : 50

      # Deployment circuit breaker (at service level)
      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }

      # Containers definiton
      container_definitions = { for container_name, container_values in service_values.containers :
        container_name => {
          cpu    = container_values.cpu
          memory = container_values.memory

          # Container image
          image = "${container_values.image}:${container_values.version}"

          # Filesystem access control
          # Set to false to allow container to write to filesystem (default)
          # Set to true for read-only filesystem (security best practice for stateless containers)
          readonlyRootFilesystem = try(container_values.readonlyRootFilesystem, false)

          # Environment variables
          environment = [for env_var, env_value in try(container_values.environment, {}) :
            {
              name  = env_var,
              value = env_value
            }
          ]

          # Secrets from AWS Secrets Manager or SSM Parameter Store
          secrets = [for secret_name, secret_arn in try(container_values.secrets, {}) :
            {
              name      = secret_name,
              valueFrom = secret_arn
            }
          ]

          # Network (camelCase for module v6.7.0)
          portMappings = [for port_name, port_number in try(container_values.ports, {}) :
            {
              containerPort = port_number,
              hostPort      = port_number,
              protocol      = "tcp"
            }
          ]

          # Mount points for volumes
          mountPoints = try(container_values.mount_points, null) != null ? [
            for mount_name, mount_config in container_values.mount_points : {
              sourceVolume  = mount_config.source_volume
              containerPath = mount_config.container_path
              readOnly      = mount_config.read_only
            }
          ] : []

          # Entrypoint
          entrypoint = try(container_values.entrypoint, [])

          # Dependencies
          dependencies = try(container_values.dependencies, [])

          # Is the container essential
          essential = try(container_values.essential, true)
        }
      }

      # Task IAM Roles and policies
      tasks_iam_role_name = "${service_name}-ecr-task"
      # Service IAM Roles and policies
      task_exec_iam_role_name = "${service_name}-ecr-exec"

      # Task execution role policies for Secrets Manager access
      task_exec_iam_role_policies = {
        secrets_manager = aws_iam_policy.ecs_secrets_access.arn
      }

      # Target group assignment - conditional based on deployment type
      load_balancer = {
        for container_name, container_values in var.routing[service_name] :
        container_name => merge(
          {
            target_group_arn = module.apps_devstg_alb_ecs_demoapps.target_groups[container_name].arn
            container_name   = container_name
            container_port   = container_values.port
          },
          # Add advanced_configuration only for BLUE_GREEN deployments
          var.ecs_deployment_type == "BLUE_GREEN" ? {
            advanced_configuration = {
              alternate_target_group_arn = module.apps_devstg_alb_ecs_demoapps.target_groups["${container_name}-bg"].arn
              production_listener_rule   = module.apps_devstg_alb_ecs_demoapps.listener_rules["https/${container_name}"].arn
              test_listener_rule         = module.apps_devstg_alb_ecs_demoapps.listener_rules["test-https/${container_name}-test"].arn
              role_arn                   = aws_iam_role.ecs_blue_green[0].arn
            }
          } : {}
        )
      }

      # Networking
      subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

      # Security group ingress rules
      security_group_ingress_rules = {
        for container_name, container_values in var.routing[service_name] :
        "ingress_${service_name}_${replace(container_name, "-", "_")}_${container_values.port}" => {
          from_port                    = container_values.port
          to_port                      = container_values.port
          ip_protocol                  = "tcp"
          referenced_security_group_id = module.apps_devstg_alb_ecs_demoapps.security_group_id
          description                  = "Allow traffic from ALB to ${container_name}"
        }
      }

      # Security group egress rules
      security_group_egress_rules = {
        egress_all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
          description = "Allow all outbound traffic"
        }
      }
    }
  }

  depends_on = [data.aws_nat_gateways.natgtw]

  tags = local.tags
}
