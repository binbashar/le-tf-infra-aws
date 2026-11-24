#=============================================#
# Launch template (EC2 / SPOT only)           #
#=============================================#
# The AMI is chosen by AWS Batch from ec2_config.image_type (ECS_AL2023 / ECS_AL2023_NVIDIA)
# or ec2_config.image_id_override, so no image_id is set here.
resource "aws_launch_template" "batch" {
  count = local.is_ec2 ? 1 : 0

  name_prefix            = "${local.name}-"
  description            = "AWS Batch ${local.name} container instances"
  update_default_version = true

  block_device_mappings {
    # Root device of the Amazon ECS-optimized Amazon Linux 2023 AMIs (standard and GPU)
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.ec2_config.root_volume_size_gib
      volume_type           = var.ec2_config.root_volume_type
      encrypted             = true
      kms_key_id            = var.ec2_config.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = var.ec2_config.metadata_hop_limit
    instance_metadata_tags      = "disabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = local.name })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.tags, { Name = local.name })
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
