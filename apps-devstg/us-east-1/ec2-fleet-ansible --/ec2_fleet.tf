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
  source = "github.com/binbashar/terraform-aws-ec2-instance.git?ref=v4.0.0"

  for_each = local.multiple_instances
  name     = "ec2-ansible-fleet-${each.key}"

  ami                    = lookup(each.value, "ami", data.aws_ami.ubuntu_linux.id)
  instance_type          = lookup(each.value, "instance_type", "t3.micro")
  key_name               = lookup(each.value, "key_name", null)
  monitoring             = true
  vpc_security_group_ids = [module.security_group_ec2_fleet.security_group_id]

  subnet_id = each.value.subnet_id

  iam_instance_profile = var.instance_profile == null ? var.instance_profile : aws_iam_instance_profile.basic_instance[0].name

  root_block_device = [
    {
    volume_size = lookup(each.value, "root_volume_size", 30)
    volume_type = lookup(each.value, "root_volume_type", "gp3")
  }
  ]

  tags = local.tags
}
