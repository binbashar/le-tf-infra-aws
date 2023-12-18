locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# local value when use for_each argument
locals {
  multiple_instances = {
    1 = {
      instance_type    = "t3a.medium"
      ami              = data.aws_ami.ubuntu_linux.id
      key_name         = data.terraform_remote_state.security.outputs.aws_key_pair_name
      # the subnet in which the instance will be created
      subnet_id        = data.terraform_remote_state.vpc.outputs.private_subnets[0]
      # root ebs device
      root_volume_size = 30
      root_volume_type = "gp3"
      # the additional ebs volume for this instance
      ebs_volume       = {
                         # whether or not this ebs will be created
                         enable = false
                         # The size of the drive in GiBs.
                         size = 8
                         # The type of EBS volume. Can be standard, gp2, gp3, io1, io2, sc1 or st1
                         # Check types in your region here https://aws.amazon.com/ebs/pricing/
                         type = "gp3"
                       }
    }
    2 = {
      instance_type    = "t3a.medium"
      ami              = data.aws_ami.ubuntu_linux.id
      key_name         = data.terraform_remote_state.security.outputs.aws_key_pair_name
      # the subnet in which the instance will be created
      subnet_id        = data.terraform_remote_state.vpc.outputs.private_subnets[1]
      # root ebs device
      root_volume_size = 30
      root_volume_type = "gp3"
      # the additional ebs volume for this instance
      ebs_volume       = {
                         # whether or not this ebs will be created
                         enable = false
                         # The size of the drive in GiBs.
                         size = 8
                         # The type of EBS volume. Can be standard, gp2, gp3, io1, io2, sc1 or st1
                         # Check types in your region here https://aws.amazon.com/ebs/pricing/
                         type = "gp3"
                       }
    }
    3 = {
      instance_type    = "t3a.medium"
      ami              = data.aws_ami.ubuntu_linux.id
      key_name         = data.terraform_remote_state.security.outputs.aws_key_pair_name
      # the subnet in which the instance will be created
      subnet_id        = data.terraform_remote_state.vpc.outputs.public_subnets[0]
      # root ebs device
      root_volume_size = 30
      root_volume_type = "gp3"
      # the additional ebs volume for this instance
      ebs_volume       = {
                         # whether or not this ebs will be created
                         enable = false
                         # The size of the drive in GiBs.
                         size = 8
                         # The type of EBS volume. Can be standard, gp2, gp3, io1, io2, sc1 or st1
                         # Check types in your region here https://aws.amazon.com/ebs/pricing/
                         type = "gp3"
                       }
    }
    4 = {
      instance_type    = "t3a.medium"
      ami              = data.aws_ami.ubuntu_linux.id
      key_name         = data.terraform_remote_state.security.outputs.aws_key_pair_name
      # the subnet in which the instance will be created
      subnet_id        = data.terraform_remote_state.vpc.outputs.public_subnets[1]
      # root ebs device
      root_volume_size = 30
      root_volume_type = "gp3"
      # the additional ebs volume for this instance
      ebs_volume       = {
                         # whether or not this ebs will be created
                         enable = false
                         # The size of the drive in GiBs.
                         size = 8
                         # The type of EBS volume. Can be standard, gp2, gp3, io1, io2, sc1 or st1
                         # Check types in your region here https://aws.amazon.com/ebs/pricing/
                         type = "gp3"
                       }
    }
  }
  ebs_volumes = {for ki,i in {for k,instance in local.multiple_instances: k=>instance if lookup(instance, "ebs_volume", null) != null}: ki=>i if i.ebs_volume.enable}
}
