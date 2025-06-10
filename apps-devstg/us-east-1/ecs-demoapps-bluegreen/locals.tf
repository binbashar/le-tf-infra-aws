
data "aws_caller_identity" "current" {}

locals {
  environment = replace(var.environment, "apps-", "")
  name        = "${var.project}-${local.environment}-apps"

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # Get Network Configuration
  networking_settings = {
    vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
    alb_subnets     = data.terraform_remote_state.vpc.outputs.private_subnets
    service_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  }
}

