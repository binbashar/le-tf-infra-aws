#
# ElasticSearch & Kibana: EC2 resources (instance, volumes, security groups, etc)
#
module "ec2_elasticsearch_kibana" {
  source = "github.com/binbashar/terraform-aws-ec2-basic-layout?ref=v0.3.34"
  prefix = var.prefix
  name   = var.name

  aws_ami_os_id          = var.aws_ami_os_id
  aws_ami_os_owner       = var.aws_ami_os_owner
  tag_approved_ami_value = var.tag_approved_ami_value

  instance_type = var.instance_type
  vpc_id        = data.terraform_remote_state.vpc-dr.outputs.vpc_id

  subnet_id                   = data.terraform_remote_state.vpc-dr.outputs.private_subnets[0]
  associate_public_ip_address = var.associate_public_ip_address
  key_pair_name               = data.terraform_remote_state.keys-dr.outputs.aws_key_pair_name
  instance_profile            = aws_iam_instance_profile.elasticsearch_kibana_dr.name
  ebs_optimized               = var.ebs_optimized
  monitoring                  = var.monitoring

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 20
      encrypted   = true
    },
  ]

  # ElasticSearch Data Volume: /var/lib/elasticsearch
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 200
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
      cidr_blocks = [
        data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
        data.terraform_remote_state.vpc-apps-dev-eks-dr.outputs.vpc_cidr_block,
      ],
      description = "Allow ElasticSearch/Kibana through Nginx"
    },
    {
      from_port = 443,
      to_port   = 443,
      protocol  = "tcp",
      cidr_blocks = [
        data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
        data.terraform_remote_state.vpc-apps-dev-eks-dr.outputs.vpc_cidr_block,
      ],
      description = "Allow ElasticSearch/Kibana through Nginx"
    },
  ]

  dns_records_internal_hosted_zone = [
    {
      zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
      name    = "kibana.${var.region_secondary}.aws.binbash.com.ar",
      type    = "A",
      ttl     = 3600
    },
    {
      zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0],
      name    = "elasticsearch.${var.region_secondary}.aws.binbash.com.ar",
      type    = "A",
      ttl     = 3600
    }
  ]

  tags = local.tags
}
