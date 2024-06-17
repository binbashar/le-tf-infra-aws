#
# ALB Security Group
#
resource "aws_security_group" "apps_devstg_alb_ecs_demoapps" {
  name        = "apps-devstg-alb-ecs-demoapps-sg"
  description = "Apps-devstg ECS Demoapps cluster load balancer"

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "allow_http_port" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80
  cidr_blocks = [
    data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block,
  ]
  description       = "Allow web access from Shared"
  security_group_id = aws_security_group.apps_devstg_alb_ecs_demoapps.id
}

resource "aws_security_group_rule" "allow_https_port" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443
  cidr_blocks = [
    data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block,
  ]
  description       = "Allow web access from Shared"
  security_group_id = aws_security_group.apps_devstg_alb_ecs_demoapps.id
}

#
# Apps-devstg Application Load Balancer for Demoapps ECS Cluster
#
module "apps_devstg_alb_ecs_demoapps" {
  source = "github.com/binbashar/terraform-aws-alb.git?ref=v9.9.0"

  name = "${local.name}-alb"

  internal = true

  enable_deletion_protection = false

  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets         = data.terraform_remote_state.vpc.outputs.private_subnets
  security_groups = [aws_security_group.apps_devstg_alb_ecs_demoapps.id]

  listeners = {
    # HTTP listener, redirects to HTTPS
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    # HTTPS listener
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = data.terraform_remote_state.certs.outputs.certificate_arn

      rules = { for container_name, container_values in local.target_groups :
        container_name => {
          actions = [
            {
              type             = "forward",
              target_group_key = container_name
            }
          ]

          conditions = [
            {
              host_header = {
                values = ["${container_values.subdomain}.${local.base_domain}"]
              }
            }
          ]
        }
      }
      # Default action
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }

  }

  target_groups = { for target_name, target_values in local.target_groups :
    # Target groups named as the associated container
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
  }

  depends_on = [data.aws_nat_gateways.natgtw]

  tags = local.tags
}

#
# DNS Records for emojivoto service
#
resource "aws_route53_record" "apps_devstg_demoapps_emojivoto" {
  provider = aws.shared

  for_each = local.routing.emojivoto

  zone_id = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id
  name    = each.value.subdomain
  type    = "A"

  alias {
    name                   = module.apps_devstg_alb_ecs_demoapps.dns_name
    zone_id                = module.apps_devstg_alb_ecs_demoapps.zone_id
    evaluate_target_health = true
  }
}
