#
# Prometheus & Grafana: EC2 resources (instance, volumes, security groups, etc)
#
module "prometheus_grafana" {
  source = "github.com/binbashar/terraform-aws-ec2-basic-layout?ref=v0.3.12"
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

  # ElasticSearch Data Volume: /var/lib/elasticsearch
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = 100
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
      description = "Allow Grafana through Nginx"
    }
  ]

  dns_records_internal_hosted_zone = [
    {
      zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
      name    = "prometheus.aws.binbash.com.ar",
      type    = "A",
      ttl     = 3600
    },
    {
      zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
      name    = "grafana.aws.binbash.com.ar",
      type    = "A",
      ttl     = 3600
    }
  ]

  tags = local.tags
}