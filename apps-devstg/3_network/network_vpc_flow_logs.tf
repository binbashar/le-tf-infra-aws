module "vpc_flow_logs" {
  source = "github.com/binbashar/terraform-aws-vpc-flowlogs.git?ref=v1.0.0"

  vpc_id             = module.vpc.vpc_id
  bucket_name_prefix = "${var.project}-${var.environment}"
  bucket_region      = var.region
  tags               = local.tags
}
