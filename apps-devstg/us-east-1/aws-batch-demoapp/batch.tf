#================================================================#
# AWS Batch: compute environment, job queue and job definitions  #
#================================================================#
module "batch" {
  source  = "terraform-aws-modules/batch/aws"
  version = "3.0.3"

  # The AWS Batch service-linked role (AWSServiceRoleForBatch) is used instead of a custom service role.
  create_service_iam_role = false

  # Instance role + instance profile for the EC2 container instances (ECS agent, ECR pull, CloudWatch Logs).
  create_instance_iam_role          = local.is_ec2
  instance_iam_role_name            = "${local.name}-instance"
  instance_iam_role_use_name_prefix = false
  instance_iam_role_description     = "AWS Batch container instance role for ${local.name}"
  instance_iam_role_additional_policies = var.ec2_config.enable_ssm ? {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  } : {}

  create_spot_fleet_iam_role          = local.create_spot_fleet_iam_role
  spot_fleet_iam_role_name            = "${local.name}-spot-fleet"
  spot_fleet_iam_role_use_name_prefix = false

  compute_environments = {
    main = {
      # name_prefix (not name) so switching compute_type can create the new environment before destroying the old one.
      name_prefix = "${local.name}-${lower(replace(var.compute_type, "_", "-"))}"

      compute_resources = {
        type      = var.compute_type
        max_vcpus = var.max_vcpus
        subnets   = local.subnets

        security_group_ids = local.security_group_ids

        # EC2 / SPOT only (the module drops these for Fargate)
        min_vcpus           = var.ec2_config.min_vcpus
        instance_types      = var.ec2_config.instance_types
        allocation_strategy = local.ec2_allocation_strategy
        bid_percentage      = var.ec2_config.bid_percentage
        ec2_key_pair        = var.ec2_config.ec2_key_pair

        ec2_configuration = [{
          image_type        = local.ec2_image_type
          image_id_override = var.ec2_config.image_id_override
        }]

        launch_template = local.is_ec2 ? {
          launch_template_id = aws_launch_template.batch[0].id
          version            = tostring(aws_launch_template.batch[0].latest_version)
        } : null

        # Tag changes replace the compute environment, so these tags are only set for EC2 instances.
        tags = local.is_ec2 ? merge(local.tags, { Name = local.name }) : {}
      }

      update_policy = var.compute_environment_update_policy
    }
  }

  job_queues = {
    main = {
      name     = local.name
      priority = var.job_queue.priority
      state    = var.job_queue.state

      compute_environment_order = {
        1 = { compute_environment_key = "main" }
      }

      job_state_time_limit_action = length(var.job_queue.job_state_time_limit_actions) > 0 ? var.job_queue.job_state_time_limit_actions : null

      create_scheduling_policy = false
    }
  }

  job_definitions = {
    for k, v in var.job_definitions : k => {
      name                  = "${local.name}-${k}"
      type                  = "container"
      platform_capabilities = [local.platform_capability]
      propagate_tags        = v.propagate_tags

      container_properties = jsonencode(local.container_properties[k])

      retry_strategy = {
        attempts         = v.retry_attempts
        evaluate_on_exit = v.retry_on_host_termination && v.retry_attempts > 1 ? local.retry_on_host_termination : null
      }

      timeout = {
        attempt_duration_seconds = v.timeout_seconds
      }
    }
  }

  tags = local.tags
}
