#
# Prometheus & Grafana: EC2 resources (instance, volumes, security groups, etc)
#
module "prometheus_grafana" {
  source = "github.com/binbashar/terraform-aws-ec2-basic-layout?ref=v0.3.34"
  prefix = var.prefix
  name   = var.name

  aws_ami_os_id          = var.aws_ami_os_id
  aws_ami_os_owner       = var.aws_ami_os_owner
  tag_approved_ami_value = var.tag_approved_ami_value

  instance_type = var.instance_type
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id

  subnet_id                   = data.terraform_remote_state.vpc.outputs.private_subnets[0]
  associate_public_ip_address = var.associate_public_ip_address
  key_pair_name               = data.terraform_remote_state.security.outputs.aws_key_pair_name
  instance_profile            = aws_iam_instance_profile.prometheus_grafana.name
  ebs_optimized               = var.ebs_optimized
  monitoring                  = var.monitoring
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 16
      encrypted   = true
    },
  ]

  # Prometheus Data Volume: /var/lib/prometheus
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
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
      description = "Allow Prometheus & Grafana through Nginx"
    },
    {
      from_port   = 443,
      to_port     = 443,
      protocol    = "tcp",
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block],
      description = "Allow Prometheus & Grafana through Nginx"
    },
    {
      from_port   = 9100,
      to_port     = 9100,
      protocol    = "tcp",
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block],
      description = "Allow Node Exporter"
    }
  ]

  dns_records_internal_hosted_zone = [
    {
      zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
      name    = "prometheus.${var.region}.aws.binbash.com.ar",
      type    = "A",
      ttl     = 3600
    },
    {
      zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
      name    = "grafana.${var.region}.aws.binbash.com.ar",
      type    = "A",
      ttl     = 3600
    }
  ]

  tags = local.tags
}
