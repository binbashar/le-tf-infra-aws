## Inspection VPC
module "vpc" {
  source                           = "cloudposse/vpc/aws"
  assign_generated_ipv6_cidr_block = false
  name                             = local.vpc_name
  cidr_block                       = local.vpc_cidr_block
  tags                             = local.tags
}

module "inspection_private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"

  name               = "inspection"
  vpc_id             = module.vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.inspection_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags

}

module "network_firewall_private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"

  name               = "firewall"
  vpc_id             = module.vpc.vpc_id
  availability_zones = local.azs
  cidr_block         = local.network_firewall_subnets_cidr[0]
  type               = "private"
  max_subnets        = 4
  tags               = local.tags
}


# Move the below code to TGW layer

data "aws_route_table" "inspection_route_table" {
  for_each  = module.inspection_private_subnets.az_subnet_ids
  subnet_id = each.value
}

resource "aws_route" "inspection_to_endpoint" {
  for_each               = { for s in data.terraform_remote_state.network-firewall.outputs["sync_states"][0] : s["availability_zone"] => s["attachment"] }
  route_table_id         = data.aws_route_table.inspection_route_table[each.key].id
  vpc_endpoint_id        = each.value[0]["endpoint_id"]
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_route_table" "network_firewall_route_table" {
  for_each  = module.network_firewall_private_subnets.az_subnet_ids
  subnet_id = each.value
}


resource "aws_route" "network_firewall_tgw" {

  for_each               = { for s in data.terraform_remote_state.network-firewall.outputs["sync_states"][0] : s["availability_zone"] => s["attachment"] }
  route_table_id         = data.aws_route_table.network_firewall_route_table[each.key].id
  transit_gateway_id     = "tgw-0f7ac1bbc7ba1a09e"
  destination_cidr_block = "0.0.0.0/0"
}
