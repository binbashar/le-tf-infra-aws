module "vpc_flow_logs" {
  source = "github.com/binbashar/terraform-aws-vpc-flowlogs.git?ref=v1.0.18"

  count              = var.enable_vpc_flow_logs ? 1 : 0
  vpc_id             = module.vpc-eks.vpc_id
  bucket_name_prefix = local.vpc_name
  log_format         = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${account-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${tcp-flags} $${log-status} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"
  tags               = local.tags
}
