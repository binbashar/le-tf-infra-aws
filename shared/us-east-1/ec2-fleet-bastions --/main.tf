#
# EC2 Fleet Bastions Security Group
#
module "security_group_ec2_bastion" {
  source = "github.com/binbashar/terraform-aws-security-group.git?ref=v4.7.0"

  name        = var.ec2_security_group_name
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    # UDP Access
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "udp"
      description = "User-service ports"
      cidr_blocks = join(",", concat([data.terraform_remote_state.vpc.outputs.vpc_cidr_block], var.allowed_ips_udp))
    },
    # SSH Access
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = join(",", concat([data.terraform_remote_state.vpc.outputs.vpc_cidr_block], var.allowed_ips_ssh))
    },
  ]
  egress_rules = ["all-all"]
}

#
# EC2 Fleet Bastions instance
#
module "ec2_bastion" {
  source = "github.com/binbashar/terraform-aws-ec2-instance.git?ref=v3.3.0"
  count  = var.ec2_instances_count
  name   = "${var.ec2_instance_name}-${count.index}"

  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = var.ec2_instance_type
  key_name               = data.terraform_remote_state.security.outputs.aws_key_pair_name
  monitoring             = false
  vpc_security_group_ids = [module.security_group_ec2_bastion.security_group_id]

  user_data = templatefile("user_data.tpl", {
    allowed_ssh_keys = var.allowed_ssh_keys
  })

  subnet_id = element(data.terraform_remote_state.vpc.outputs.public_subnets, count.index)

  tags = local.tags
}

#
# Create a specified number of EIPs on VPC scope
#
resource "aws_eip" "bastion_instance" {
  vpc   = true
  count = var.ec2_instances_count
}

#
# Elastic IP association
#
resource "aws_eip_association" "eip_assoc" {
  count         = var.ec2_instances_count
  instance_id   = element(module.ec2_bastion.*.id, count.index)
  allocation_id = element(aws_eip.bastion_instance.*.id, count.index)
}