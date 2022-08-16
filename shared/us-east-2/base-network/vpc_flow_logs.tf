module "vpc_flow_logs" {
  source = "github.com/binbashar/terraform-aws-vpc-flowlogs.git?ref=v1.0.13"

  vpc_id             = module.vpc.vpc_id
  bucket_name_prefix = "${var.project}-${var.environment}-dr"
  tags               = local.tags
}
