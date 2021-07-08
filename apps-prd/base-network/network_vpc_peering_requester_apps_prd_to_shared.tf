#
# VPC Peering Connection with Share: Requester Side
#
# Consider 'destination_cidr_block' parameter will be the CIDR of the remote VPC/Subnets  (originator of the VPC
# peering request) and 'route_table_id' the route table ID to add the destination route to.
#

#
# VPC Apps Prd w/ Shared
#
resource "aws_vpc_peering_connection" "apps_prd_vpc_with_shared_vpc" {
  count = var.vpc_shared_created && !data.terraform_remote_state.vpc-network.outputs.enable_tgw ? 1 : 0

  peer_owner_id = var.shared_account_id
  peer_vpc_id   = data.terraform_remote_state.vpc-shared.outputs.vpc_id
  vpc_id        = module.vpc.vpc_id
  auto_accept   = false

  tags = merge(map("Name", "requester-apps-prd-to-shared"), local.tags)
}

#
# Update Route Tables to go through the VPC Peering Connection
# ---
# Both private and public subnets traffic will be routed and permitted through VPC Peerings (filtered by Private Inbound NACLs)
# If stryctly needed private subnets must be exposed via Load Balancers (NLBs || ALBs)
# reducing public IPs exposure whenever possible.
# read more: https://github.com/binbashar/le-tf-infra-aws/issues/49
#
resource "aws_route" "priv_route_table_1_apps_prd_vpc_to_shared_vpc" {
  count = var.vpc_shared_created && !data.terraform_remote_state.vpc-network.outputs.enable_tgw ? 1 : 0

  route_table_id            = element(module.vpc.private_route_table_ids, 0)
  destination_cidr_block    = data.terraform_remote_state.vpc-shared.outputs.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.apps_prd_vpc_with_shared_vpc[0].id
}

resource "aws_route" "pub_route_table_1_apps_prd_vpc_to_shared_vpc" {
  count = var.vpc_shared_created && !data.terraform_remote_state.vpc-network.outputs.enable_tgw ? 1 : 0

  route_table_id            = element(module.vpc.public_route_table_ids, 0)
  destination_cidr_block    = data.terraform_remote_state.vpc-shared.outputs.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.apps_prd_vpc_with_shared_vpc[0].id
}
