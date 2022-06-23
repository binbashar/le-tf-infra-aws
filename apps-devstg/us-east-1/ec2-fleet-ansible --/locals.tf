locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

#local when need to use for_each argument
locals {
  multiple_instances = {
    1 = {
      subnet_id = data.terraform_remote_state.vpc.outputs.private_subnets[0]
    }
    2 = {
      subnet_id = data.terraform_remote_state.vpc.outputs.private_subnets[1]
    }
    3 = {
      subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[0]
    }
    4 = {
      subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[1]
    }
  }
}
