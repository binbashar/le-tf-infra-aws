locals {
  environment = replace(var.environment, "apps-", "")
  name        = "${var.project}-${local.environment}-batch-demoapp"

  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }

  #===========================================#
  # Compute backend                           #
  #===========================================#
  is_fargate = contains(["FARGATE", "FARGATE_SPOT"], var.compute_type)
  is_ec2     = !local.is_fargate
  is_spot    = var.compute_type == "SPOT"

  platform_capability = local.is_fargate ? "FARGATE" : "EC2"

  ec2_image_type = coalesce(
    var.ec2_config.image_type,
    var.ec2_config.gpu_enabled ? "ECS_AL2023_NVIDIA" : "ECS_AL2023",
  )

  ec2_allocation_strategy = coalesce(
    var.ec2_config.allocation_strategy,
    local.is_spot ? "SPOT_PRICE_CAPACITY_OPTIMIZED" : "BEST_FIT_PROGRESSIVE",
  )

  # The spot fleet role is only used by the BEST_FIT allocation strategy, but the module expects it for SPOT.
  create_spot_fleet_iam_role = local.is_spot

  #===========================================#
  # Networking                                #
  #===========================================#
  vpc_id  = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets = var.subnets_tier == "private" ? data.terraform_remote_state.vpc.outputs.private_subnets : data.terraform_remote_state.vpc.outputs.public_subnets

  security_group_ids = concat([aws_security_group.batch.id], var.additional_security_group_ids)

  #===========================================#
  # Job definitions                           #
  #===========================================#
  log_group_name = "/aws/batch/${local.name}"

  # Secret ARNs as IAM resources. A Secrets Manager valueFrom may end in ":json-key:version-stage:version-id",
  # so it is cut down to the secret ARN (first 7 ":"-separated fields).
  secret_values = distinct(flatten([for k, v in var.job_definitions : values(v.secrets)]))
  secretsmanager_secret_arns = distinct([
    for arn in local.secret_values : join(":", slice(split(":", arn), 0, 7))
    if split(":", arn)[2] == "secretsmanager"
  ])
  ssm_parameter_arns = distinct([for arn in local.secret_values : arn if split(":", arn)[2] == "ssm"])

  # Container properties per job definition. Empty or not-applicable keys are left out on purpose:
  # the AWS provider normalizes container_properties and empty values would show as a perpetual diff.
  container_properties = {
    for k, v in var.job_definitions : k => merge(
      {
        image            = v.image
        jobRoleArn       = aws_iam_role.job.arn
        executionRoleArn = aws_iam_role.execution.arn

        resourceRequirements = concat(
          [
            { type = "VCPU", value = tostring(v.vcpu) },
            { type = "MEMORY", value = tostring(v.memory_mib) },
          ],
          v.gpu > 0 ? [{ type = "GPU", value = tostring(v.gpu) }] : [],
        )

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = local.log_group_name
            awslogs-region        = var.region
            awslogs-stream-prefix = k
          }
        }
      },
      length(v.command) > 0 ? { command = v.command } : {},
      length(v.environment) > 0 ? {
        environment = [for name, value in v.environment : { name = name, value = value }]
      } : {},
      length(v.secrets) > 0 ? {
        secrets = [for name, value_from in v.secrets : { name = name, valueFrom = value_from }]
      } : {},
      local.is_fargate ? {
        networkConfiguration = {
          assignPublicIp = var.assign_public_ip ? "ENABLED" : "DISABLED"
        }
        fargatePlatformConfiguration = {
          platformVersion = v.fargate_platform_version
        }
        runtimePlatform = {
          operatingSystemFamily = "LINUX"
          cpuArchitecture       = v.cpu_architecture
        }
      } : {},
      local.is_fargate && v.ephemeral_storage_gib != null ? {
        ephemeralStorage = { sizeInGiB = v.ephemeral_storage_gib }
      } : {},
    )
  }

  # Retry on host termination (e.g. Spot interruption) and exit on anything else.
  # Map keys are sorted, the numeric prefix keeps the evaluation order.
  retry_on_host_termination = {
    "1_retry_host_termination" = {
      action           = "RETRY"
      on_status_reason = "Host EC2*"
    }
    "2_exit_otherwise" = {
      action    = "EXIT"
      on_reason = "*"
    }
  }

  #===========================================#
  # Notifications                             #
  #===========================================#
  notifications_from_remote_state = var.failure_notifications.enabled && var.failure_notifications.sns_topic_arn == null

  failure_notifications_sns_topic_arn = var.failure_notifications.enabled ? coalesce(
    var.failure_notifications.sns_topic_arn,
    try(data.terraform_remote_state.notifications[0].outputs.sns_topic_arn_monitoring, null),
  ) : null
}
