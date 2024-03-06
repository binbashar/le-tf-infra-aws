locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# local value when use for_each argument
locals {
  # these are the defaults used to create instances
  # they can be overwritten in the instance definition
  instances_defaults = {
    instance_type = "t3a.medium"
    ami           = data.aws_ami.ubuntu_linux.id
    key_name      = data.terraform_remote_state.security.outputs.aws_key_pair_name
    # root ebs device
    root_volume_size = 30
    root_volume_type = "gp3"

    monitoring = true

    # whether or not it is a spot instance
    create_spot_instance = true
  }
  # the instances
  # subnet_id is mandatory
  # the other params can be set or the defaults will be used
  # extra ebs volumes can be set setting for each instance this
  #
  #    ebs_volume       = {
  #                       # whether or not this ebs will be created
  #                       enable = false
  #                       # The size of the drive in GiBs.
  #                       size = 8
  #                       # The type of EBS volume. Can be standard, gp2, gp3, io1, io2, sc1 or st1
  #                       # Check types in your region here https://aws.amazon.com/ebs/pricing/
  #                       type = "gp3"
  #                     }
  multiple_instances = {
    1 = {
      # MANDATORY the subnet in which the instance will be created
      subnet_id = data.terraform_remote_state.vpc.outputs.private_subnets[0]

      instance_type = "t3a.medium"
      ami           = data.aws_ami.ubuntu_linux.id
      key_name      = data.terraform_remote_state.security.outputs.aws_key_pair_name
      # root ebs device
      root_volume_size = 30
      root_volume_type = "gp3"
      # the additional ebs volume for this instance
      ebs_volume = {
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
      # MANDATORY the subnet in which the instance will be created
      subnet_id = data.terraform_remote_state.vpc.outputs.private_subnets[1]
    }
    3 = {
      # MANDATORY the subnet in which the instance will be created
      subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[0]
    }
    4 = {
      # MANDATORY the subnet in which the instance will be created
      subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[1]
    }
  }
  ebs_volumes = { for ki, i in { for k, instance in local.multiple_instances : k => instance if lookup(instance, "ebs_volume", null) != null } : ki => i if i.ebs_volume.enable }
}
