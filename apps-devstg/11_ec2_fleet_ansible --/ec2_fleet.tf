#
# EC2 Fleet Security Group
#
module "security_group_ec2_fleet" {
  source = "git::git@github.com:binbashar/terraform-aws-security-group.git?ref=v3.4.0"

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
  source = "git::git@github.com:binbashar/terraform-aws-ec2-instance.git?ref=v2.12.0"

  name           = "ec2-fleet-ansible"
  instance_count = 5

  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = "t2.micro"
  key_name               = data.terraform_remote_state.security.outputs.aws_key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.security_group_ec2_fleet.this_security_group_id]

  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.private_subnets[0],
    data.terraform_remote_state.vpc.outputs.private_subnets[1],
    data.terraform_remote_state.vpc.outputs.private_subnets[2]
  ]

  tags = local.tags
}
