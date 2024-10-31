module "vpc_flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  source = "github.com/binbashar/terraform-aws-vpc-flowlogs.git?ref=v1.0.18"

  vpc_id             = module.vpc.vpc_id
  bucket_name_prefix = "${local.vpc_name}-flow-logs"
  log_format         = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${account-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${tcp-flags} $${log-status} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"
  enable_versioning  = true
  tags               = local.tags
}
