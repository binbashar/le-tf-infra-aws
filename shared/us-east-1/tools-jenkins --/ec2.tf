#
# Jenkins Master: EC2 resources (instance, volumes, security groups, etc)
#
module "ec2_jenkins_master" {
  source = "github.com/binbashar/terraform-aws-ec2-basic-layout.git?ref=v0.3.34"
  prefix = var.prefix
  name   = var.name

  aws_ami_os_id          = var.aws_ami_os_id
  aws_ami_os_owner       = var.aws_ami_os_owner
  tag_approved_ami_value = var.tag_approved_ami_value

  instance_type    = var.instance_type
  vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  instance_profile = aws_iam_instance_profile.basic_instance.name

  subnet_id                   = data.terraform_remote_state.vpc.outputs.private_subnets[0]
  associate_public_ip_address = var.associate_public_ip_address
  key_pair_name               = data.terraform_remote_state.keys.outputs.aws_key_pair_name
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
      from_port   = 80,
      to_port     = 80,
      protocol    = "tcp",
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block],
      description = "Allow Nginx via HTTP"
    },
    {
      from_port   = 443,
      to_port     = 443,
      protocol    = "tcp",
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block],
      description = "Allow Nginx via HTTPS"
    }
  ]

  dns_records_internal_hosted_zone = [{
    zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
    name    = "jenkins.aws.binbash.com.ar",
    type    = "A",
    ttl     = 300
  }]

  tags = local.tags
}
