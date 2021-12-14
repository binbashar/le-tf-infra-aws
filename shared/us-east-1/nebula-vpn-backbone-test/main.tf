#
# EC2 VPN Security Group
#
module "security_group_ec2_vpn" {
  source = "github.com/binbashar/terraform-aws-security-group.git?ref=v4.2.0"

  name        = "ec2-nebula-vpn"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_cidr_blocks = [
    data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
  ]

  ingress_rules = ["ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "udp"
      description = "User-service ports"
      cidr_blocks = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
    },
  ]
  egress_rules  = ["all-all"]
}

#
# EC2 VPN for testing purposes
#
module "ec2_vpn" {
  source = "github.com/binbashar/terraform-aws-ec2-instance.git?ref=v2.19.0"

  name           = "ec2-nebula-vpn"
  instance_count = var.aws_ec2_instances_count

  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = var.aws_ec2_instance_type
  key_name               = data.terraform_remote_state.security.outputs.aws_key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.security_group_ec2_vpn.security_group_id]

  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.private_subnets[0],
    data.terraform_remote_state.vpc.outputs.private_subnets[1],
    data.terraform_remote_state.vpc.outputs.public_subnets[0],
    data.terraform_remote_state.vpc.outputs.public_subnets[1]
  ]

  tags = local.tags
}

#
# Elastic IP to associate to the server endpoint
#
resource "aws_eip" "vpn_instance" {
  vpc   = true
  count = var.aws_ec2_instances_count
}

resource "aws_eip_association" "eip_assoc" {
  count = var.aws_ec2_instances_count
  instance_id   = "${element(module.ec2_vpn.*.id, count.index)}"
  allocation_id = "${element(aws_eip.vpn_instance.*.id, count.index)}"
}