#
# EC2 Fleet Security Group
#
module "security_group_ec2_fleet" {
  source = "github.com/binbashar/terraform-aws-security-group.git?ref=v4.2.0"

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
  source = "github.com/binbashar/terraform-aws-ec2-instance.git?ref=v2.19.0"

  name           = "ec2-fleet"
  instance_count = 4

  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = "t2.nano"
  key_name               = data.terraform_remote_state.security.outputs.aws_key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.security_group_ec2_fleet.security_group_id]

  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.private_subnets[0],
    data.terraform_remote_state.vpc.outputs.private_subnets[1],
    data.terraform_remote_state.vpc.outputs.public_subnets[0],
    data.terraform_remote_state.vpc.outputs.public_subnets[1]
  ]

  tags = local.tags
}
