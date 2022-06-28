#
# EC2 Fleet Security Group
#
module "security_group_ec2_fleet" {
  source = "github.com/binbashar/terraform-aws-security-group.git?ref=v4.9.0"

  name        = "ec2-fleet"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_cidr_blocks = [
    data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
  ]

  ingress_rules = ["all-icmp"]
  egress_rules  = ["all-all"]
}

#
# EC2 Fleet for testing purposes
#
module "ec2_fleet" {
  source = "github.com/binbashar/terraform-aws-ec2-instance.git?ref=v4.0.0"

  for_each = local.multiple_instances
  name     = "ec2-fleet-${each.key}"

  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = "t2.nano"
  key_name               = data.terraform_remote_state.security.outputs.aws_key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.security_group_ec2_fleet.security_group_id]

  subnet_id = each.value.subnet_id


  tags = local.tags
}
