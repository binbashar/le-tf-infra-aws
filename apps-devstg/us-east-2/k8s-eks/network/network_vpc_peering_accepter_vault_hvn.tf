#
# VPC Peering Connection with Apps Dev: Accepter Side
#
resource "aws_vpc_peering_connection_accepter" "with_vault_hvn" {
  count = var.vpc_vault_hvn_created == true ? 1 : 0

  vpc_peering_connection_id = var.vpc_vault_hvn_peering_connection_id
  auto_accept               = true

  tags = merge(map("Name", "accepter-shared-from-vault-hvn"), local.tags)
}

#
# Update Route Tables to go through the VPC Peering Connection
# ---
# Both private and public subnets traffic will be routed and permitted through VPC Peerings (filtered by Private Inbound NACLs)
# If stryctly needed private subnets must be exposed via Load Balancers (NLBs || ALBs)
# reducing public IPs exposure whenever possible.
# read more: https://github.com/binbashar/le-tf-infra-aws/issues/49
#
resource "aws_route" "priv_route_table_1_to_vault_hvn_vpc" {
  count = var.vpc_vault_hvn_created == true ? 1 : 0

  route_table_id            = element(module.vpc-eks.private_route_table_ids, 0)
  destination_cidr_block    = var.vpc_vault_hvn_cidr
  vpc_peering_connection_id = var.vpc_vault_hvn_peering_connection_id
}

resource "aws_route" "pub_route_table_1_to_vault_hvn_vpc" {
  count = var.vpc_vault_hvn_created == true ? 1 : 0

  route_table_id            = element(module.vpc-eks.public_route_table_ids, 0)
  destination_cidr_block    = var.vpc_vault_hvn_cidr
  vpc_peering_connection_id = var.vpc_vault_hvn_peering_connection_id
}
