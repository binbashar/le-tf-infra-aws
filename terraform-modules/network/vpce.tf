
# VPC Endpoints
module "vpc_endpoints" {
  source = "github.com/binbashar/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v5.5.3"

  for_each = local.vpc_endpoints

  vpc_id = module.vpc.vpc_id

  endpoints = {
    endpoint = merge(each.value,
      {
        route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
      }
    )
  }

  tags = local.tags
}
