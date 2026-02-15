#
# Apps-devstg Application Load Balancer for Demoapps ECS Cluster
#
module "apps_devstg_alb_ecs_demoapps" {
  source = "github.com/binbashar/terraform-aws-alb.git?ref=v10.0.2"

  name = "${local.name}-alb"

  internal = true

  enable_deletion_protection = false

  vpc_id  = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # Security group configuration (module-managed)
  create_security_group      = true
  security_group_name        = "apps-devstg-alb-ecs-demoapps-sg"
  security_group_description = "Apps-devstg ECS Demoapps cluster load balancer"

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block
      description = "Allow HTTP from Shared VPC"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block
      description = "Allow HTTPS from Shared VPC"
    }
    alt_http = {
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      cidr_ipv4   = data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block
      description = "Allow test HTTP from Shared VPC (blue-green)"
    }
    alt_https = {
      from_port   = 8443
      to_port     = 8443
      ip_protocol = "tcp"
      cidr_ipv4   = data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block
      description = "Allow test HTTPS from Shared VPC (blue-green)"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }

  listeners = local.alb_listeners

  target_groups = merge(
    # Primary target groups (always created)
    { for target_name, target_values in local.target_groups :
      target_name => {
        name             = "ecs-${target_name}"
        protocol         = "HTTP"
        protocol_version = try(target_values.protocol_version, "HTTP1")
        port             = target_values.port
        target_type      = "ip"

        health_check = {
          interval            = 30
          port                = target_values.port
          healthy_threshold   = 2
          unhealthy_threshold = 10
          protocol            = "HTTP"
          matcher             = try(target_values.health_check.matcher, null)
        }
        # ECS handles the attachment
        create_attachment = false
      }
    },
    # Secondary target groups for BLUE_GREEN deployment (only created when BLUE_GREEN is enabled)
    var.ecs_deployment_type == "BLUE_GREEN" ? {
      for target_name, target_values in local.target_groups :
      "${target_name}-bg" => {
        name             = "ecs-${target_name}-bg"
        protocol         = "HTTP"
        protocol_version = try(target_values.protocol_version, "HTTP1")
        port             = target_values.port
        target_type      = "ip"

        health_check = {
          interval            = 30
          port                = target_values.port
          healthy_threshold   = 2
          unhealthy_threshold = 10
          protocol            = "HTTP"
          matcher             = try(target_values.health_check.matcher, null)
        }
        # ECS handles the attachment
        create_attachment = false
      }
    } : {}
  )

  depends_on = [data.aws_nat_gateways.natgtw]

  tags = local.tags
}

#
# DNS Records for all services
#
resource "aws_route53_record" "apps_devstg_demoapps" {
  provider = aws.shared

  for_each = local.target_groups

  zone_id = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id
  name    = "${each.value.subdomain}.${local.environment}"
  type    = "A"

  alias {
    name                   = module.apps_devstg_alb_ecs_demoapps.dns_name
    zone_id                = module.apps_devstg_alb_ecs_demoapps.zone_id
    evaluate_target_health = true
  }
}
