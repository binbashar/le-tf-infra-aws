#
# EC2 Fleet Security Group
#
module "security_group_ec2_fleet" {
  source = "github.com/binbashar/terraform-aws-security-group.git?ref=v4.9.0"

  name        = "ec2-ansible-fleet"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_cidr_blocks = [
    data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
    data.terraform_remote_state.vpc-shared.outputs.vpc_cidr_block
  ]

  ingress_rules = ["ssh-tcp", "all-icmp"]
  egress_rules  = ["all-all"]
}

#
# EC2 Fleet for ansible playbooks testing
#
module "ec2_ansible_fleet" {
  source = "github.com/binbashar/terraform-aws-ec2-instance.git?ref=v5.5.0"

  for_each = local.multiple_instances
  name     = "ec2-ansible-fleet-${each.key}"

  create_spot_instance = lookup(each.value, "create_spot_instance", local.instances_defaults.create_spot_instance)

  ami                    = lookup(each.value, "ami", local.instances_defaults.ami)
  instance_type          = lookup(each.value, "instance_type", local.instances_defaults.instance_type)
  key_name               = lookup(each.value, "key_name", local.instances_defaults.key_name)
  monitoring             = lookup(each.value, "monitoring", local.instances_defaults.monitoring)
  vpc_security_group_ids = [module.security_group_ec2_fleet.security_group_id]

  subnet_id = each.value.subnet_id

  iam_instance_profile = var.instance_profile == null ? var.instance_profile : aws_iam_instance_profile.basic_instance[0].name

  root_block_device = [
    {
      volume_size = lookup(each.value, "root_volume_size", local.instances_defaults.root_volume_size)
      volume_type = lookup(each.value, "root_volume_type", local.instances_defaults.root_volume_type)
    }
  ]

  tags = local.tags
}
