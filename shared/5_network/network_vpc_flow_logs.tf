module "vpc_flow_logs" {
    source = "git::git@github.com:binbashar/terraform-aws-vpc-flowlogs.git?ref=v0.0.3"
    
    vpc_id = "${module.vpc.vpc_id}"
    bucket_name_prefix = "${var.project}-${var.environment}"
    bucket_region = "${var.region}"
    tags = "${local.tags}"
}