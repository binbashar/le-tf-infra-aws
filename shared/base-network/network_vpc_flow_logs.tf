module "vpc_flow_logs" {
  source = "github.com/binbashar/terraform-aws-vpc-flowlogs.git?ref=v1.0.9"

  vpc_id             = module.vpc.vpc_id
  bucket_name_prefix = "${var.project}-${var.environment}"
  tags               = local.tags

}
