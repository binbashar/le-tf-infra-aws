#
# Network Resources
#
module "vpc" {
  source = "github.com/binbashar/terraform-aws-vpc.git?ref=v3.1.0"

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
  manage_default_network_acl    = var.manage_default_network_acl
  public_dedicated_network_acl  = var.public_dedicated_network_acl  // use dedicated network ACL for the public subnets.
  private_dedicated_network_acl = var.private_dedicated_network_acl // use dedicated network ACL for the private subnets.
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )

  # VPN Gateway
  amazon_side_asn   = var.vpn_gateway_amazon_side_asn
  customer_gateways = var.vpc_enable_vpn_gateway ? local.cgws : {}

  # Tags
  tags = local.tags
}

# VPC Endpoints
module "vpc_endpoints" {
  source = "github.com/binbashar/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v3.1.0"

  for_each = var.vpc_endpoints

  vpc_id = module.vpc.vpc_id

  endpoints = {
    endpoint = merge(each.value,
      {
        route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
      }
    )
  }

  tags = local.tags

  depends_on = [module.vpc]
}

#
# KMS VPC Endpoint: Security Group
#
resource "aws_security_group" "kms_vpce" {
  count       = length(lookup(var.vpc_endpoints, "kms", {})) > 0 ? 1 : 0
  name        = "kms_vpce"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

  depends_on = [module.vpc]
}

####################
# TGW Route tables #
####################

# Update public RT
resource "aws_route" "public_rt_routes_to_tgw" {

  # For TWG CDIRs
  for_each = {
    for k, v in var.tgw_cidrs :
    k => v if var.enable_tgw && length(var.tgw_cidrs) > 0
  }

  # ...add a route into the network public RT
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = each.value
  transit_gateway_id     = data.terraform_remote_state.tgw[0].outputs.tgw_id

}

# Update private RT
resource "aws_route" "private_rt_routes_to_tgw" {

  # For TWG CDIRs
  for_each = {
    for k, v in var.tgw_cidrs :
    k => v if var.enable_tgw && length(var.tgw_cidrs) > 0
  }

  # ...add a route into the network private RT
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = each.value
  transit_gateway_id     = data.terraform_remote_state.tgw[0].outputs.tgw_id
}
