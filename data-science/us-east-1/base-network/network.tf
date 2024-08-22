#
# VPC
#
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v3.19.0"

  name = local.vpc_name
  cidr = local.vpc_cidr_block

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway   = var.vpc_enable_nat_gateway
  single_nat_gateway   = var.vpc_single_nat_gateway
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  enable_vpn_gateway   = var.vpc_enable_vpn_gateway

  # Use a custom network ACL rules for private and public subnets
  manage_default_network_acl    = false
  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )

  #   public_subnet_tags  = local.public_subnet_tags
  #   private_subnet_tags = local.private_subnet_tags
  tags = local.tags
}

# VPC Endpoints
locals {
  vpc_endpoints = merge({
    # S3
    s3 = {
      service      = "s3"
      service_type = "Gateway"
    }
    # DynamamoDB
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
    }
    },
  )
}

module "vpc_endpoints" {
  source = "github.com/binbashar/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v3.19.0"

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

####################
# TGW Route tables #
####################

# Update public RT
# resource "aws_route" "public_rt_routes_to_tgw" {

#   # For TWG CDIRs
#   for_each = {
#     for k, v in var.tgw_cidrs :
#     k => v if var.enable_tgw && length(var.tgw_cidrs) > 0
#   }

#   # ...add a route into the network public RT
#   route_table_id         = module.vpc.public_route_table_ids[0]
#   destination_cidr_block = each.value
#   transit_gateway_id     = data.terraform_remote_state.tgw[0].outputs.tgw_id

# }

# Update private RT
# resource "aws_route" "private_rt_routes_to_tgw" {

#   # If TGW enable
#   count = var.enable_tgw ? 1 : 0

#   # ...add a route into the network private RT
#   route_table_id         = module.vpc.private_route_table_ids[0]
#   destination_cidr_block = "0.0.0.0/0"
#   transit_gateway_id     = data.terraform_remote_state.tgw[0].outputs.tgw_id
# }
