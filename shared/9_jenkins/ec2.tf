#
# Jenkins Master: EC2 resources (instance, volumes, security groups, etc)
#
module "jenkins_master" {
  source = "github.com/binbashar/terraform-aws-ec2-basic-layout?ref=v0.3.8"
  prefix = var.prefix
  name   = var.name

  aws_ami_os_id    = var.aws_ami_os_id
  aws_ami_os_owner = var.aws_ami_os_owner

  instance_type = var.instance_type
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id

  subnet_id                   = data.terraform_remote_state.vpc.outputs.private_subnets[0]
  associate_public_ip_address = var.associate_public_ip_address
  key_pair_name               = data.terraform_remote_state.security.outputs.aws_key_pair_name
  ebs_optimized               = var.ebs_optimized
  monitoring                  = var.monitoring
  user_data_base64            = base64encode(local.user_data)

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 20
      encrypted   = true
    },
  ]

  security_group_rules = [
    {
      from_port   = 22,
      to_port     = 22,
      protocol    = "tcp",
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block],
      description = "Allow SSH"
    },
    {
      from_port = 80,
      to_port   = 80,
      protocol  = "tcp",
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block],
      description = "Allow Nginx via HTTP"
    },
    {
      from_port = 443,
      to_port   = 443,
      protocol  = "tcp",
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block],
      description = "Allow Nginx via HTTPS"
    }
  ]

  policy_arn = [ aws_iam_policy.jenkins_master.arn ]

  tags = local.tags
}