#
# Webhooks Proxy EC2 resources (instance, volumes, security groups, etc)
#
module "ec2_webhooks_proxy" {
  source = "github.com/binbashar/terraform-aws-ec2-basic-layout.git?ref=v0.3.34"
  prefix = var.prefix
  name   = var.name

  aws_ami_os_id          = var.aws_ami_os_id
  aws_ami_os_owner       = var.aws_ami_os_owner
  tag_approved_ami_value = var.tag_approved_ami_value

  instance_type = var.instance_type
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id

  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  associate_public_ip_address = var.associate_public_ip_address
  key_pair_name               = data.terraform_remote_state.keys.outputs.aws_key_pair_name
  ebs_optimized               = var.ebs_optimized
  monitoring                  = var.monitoring

  # Mount point: /
  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 16
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
      from_port   = 8080,
      to_port     = 8080,
      protocol    = "tcp",
      cidr_blocks = ["0.0.0.0/0"],
      description = "Allow Nginx (Jenkins) via HTTP"
    }
  ]

  dns_records_internal_hosted_zone = [{
    zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
    name    = "webhooks.aws.binbash.com.ar",
    type    = "A",
    ttl     = 3600
  }]

  dns_records_public_hosted_zone = [{
    zone_id = data.terraform_remote_state.dns.outputs.aws_public_zone_id[0],
    name    = "webhooks.binbash.com.ar",
    type    = "A",
    ttl     = 3600
  }]

  tags = local.tags
}
