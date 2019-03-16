#
# VPC Peering Connection with Apps Dev/Stage: Accepter Side
#
data "aws_vpc_peering_connection" "with_dev" {
    vpc_id      = "${var.dev_vpc_id}"
    peer_vpc_id = "${module.vpc.vpc_id}"
    cidr_block  = "${var.dev_vpc_cidr_block}"
}

resource "aws_vpc_peering_connection_accepter" "with_dev" {
    vpc_peering_connection_id = "${data.aws_vpc_peering_connection.with_dev.id}"
    auto_accept               = true

    tags = "${merge(map("side", "accepter"), local.tags)}"
}

#
# Update Route Tables to go through the VPC Peering Connection
#
resource "aws_route" "priv_route_table_1_to_dev_vpc" {
    route_table_id            = "${element(module.vpc.private_route_table_ids, 0)}"
    destination_cidr_block    = "${var.dev_vpc_cidr_block}"
    vpc_peering_connection_id = "${data.aws_vpc_peering_connection.with_dev.id}"
}
resource "aws_route" "pub_route_table_1_to_dev_vpc" {
    route_table_id            = "${element(module.vpc.public_route_table_ids, 0)}"
    destination_cidr_block    = "${var.dev_vpc_cidr_block}"
    vpc_peering_connection_id = "${data.aws_vpc_peering_connection.with_dev.id}"
}