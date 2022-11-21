####################
# ALB WAFv2 Demo
####################

locals {
  alb_waf_example_name = "${var.environment}-alb-waf-example"
  vpc_id               = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress_cidr_blocks  = concat([data.terraform_remote_state.vpc.outputs.vpc_cidr_block], var.ingress_cidr_blocks)
  subnets              = var.alb_waf_example.internal ? data.terraform_remote_state.vpc.outputs.private_subnets : data.terraform_remote_state.vpc.outputs.public_subnets
  certificate_arn      = data.terraform_remote_state.certificates.outputs.certificate_arn
}

module "security_group_waf_example" {
  create_sg = var.alb_waf_example.enabled
  source    = "github.com/binbashar/terraform-aws-security-group.git?ref=v4.9.0"

  name                = "${local.alb_waf_example_name}-sg"
  description         = "Security group for example usage with ALB"
  vpc_id              = local.vpc_id
  ingress_cidr_blocks = local.ingress_cidr_blocks
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "alb_waf_example" {
  create_lb = var.alb_waf_example.enabled
  source    = "github.com/binbashar/terraform-aws-alb.git?ref=v7.0.0"

  name               = local.alb_waf_example_name
  load_balancer_type = var.alb_waf_example.type

  internal        = var.alb_waf_example.internal
  vpc_id          = local.vpc_id
  subnets         = local.subnets
  security_groups = [module.security_group_waf_example.security_group_id]
  http_tcp_listeners = [
    # Forward action is default, either when defined or undefined
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed message"
        status_code  = "403"
      }
    },
  ]
  # https_listeners = [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = module.acm.acm_certificate_arn
  #     target_group_index = 1
  #   },
  # ]

  tags = local.tags
}

# resource "aws_route53_record" "alb_waf_example_aws_binbash_com_ar" {
#   provider = aws.shared-route53
#   zone_id  = data.terraform_remote_state.dns-shared.outputs.aws_internal_zone_id[0]
#   name     = local.alb_waf_example_name
#   type     = "A"

#   alias {
#     evaluate_target_health = false
#     name                   = module.alb_waf_example.lb_dns_name
#     zone_id                = module.alb_waf_example.lb_zone_id
#   }
# }