####################
# ALB WAFv2 Demo
####################
module "alb_waf_example" {
  count   = var.alb_waf_example.enabled ? 1 : 0
  source  = "umotif-public/alb/aws"
  version = "2.1.0"

  name_prefix        = "alb-waf-example"
  load_balancer_type = "application"
  internal           = true
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets            = data.terraform_remote_state.vpc.outputs.private_subnets
}