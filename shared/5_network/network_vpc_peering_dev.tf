#
# VPC Peering Connection with Dev: Accepter Side
#
resource "aws_vpc_peering_connection_accepter" "with_dev" {
  vpc_peering_connection_id = "${data.terraform_remote_state.vpc-dev.vpc_peering_id_dev_with_shared}"
  auto_accept               = true

  tags = "${merge(map("Name", "accepter-shared-from-dev"), local.tags)}"
}

#
# Update Route Tables to go through the VPC Peering Connection
#
resource "aws_route" "priv_route_table_1_to_dev_vpc" {
  route_table_id            = "${element(module.vpc.private_route_table_ids, 0)}"
  destination_cidr_block    = "${data.terraform_remote_state.vpc-dev.vpc_cidr_block}"
  vpc_peering_connection_id = "${data.terraform_remote_state.vpc-dev.vpc_peering_id_dev_with_shared}"
}

resource "aws_route" "pub_route_table_1_to_dev_vpc" {
  route_table_id            = "${element(module.vpc.public_route_table_ids, 0)}"
  destination_cidr_block    = "${data.terraform_remote_state.vpc-dev.vpc_cidr_block}"
  vpc_peering_connection_id = "${data.terraform_remote_state.vpc-dev.vpc_peering_id_dev_with_shared}"
}