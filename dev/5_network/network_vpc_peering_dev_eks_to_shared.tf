#
# VPC Peering Connection with Share: Requester Side
#
# Consider 'destination_cidr_block' parameter will be the CIDR of the remote VPC/Subnets  (originator of the VPC
# peering request) and 'route_table_id' the route table ID to add the destination route to.
#

#
# VPC Dev-EKS w/ shared
#
resource "aws_vpc_peering_connection" "dev_eks_vpc_with_shared_vpc" {
  peer_owner_id = "${var.shared_account_id}"
  peer_vpc_id   = "${data.terraform_remote_state.vpc-shared.vpc_id}"
  vpc_id        = "${data.terraform_remote_state.vpc-eks.vpc_id}"
  auto_accept   = false

  //    tags = "${merge(map("side", "accepter"), ${local.tags}"
  tags = "${merge(map("Name", "requester-dev-eks-to-shared"), local.tags)}"
}

#
# Update Route Tables to go through the VPC Peering Connection
#
resource "aws_route" "priv_route_table_1_dev_eks_vpc_to_shared_vpc" {
  route_table_id            = "${element(data.terraform_remote_state.vpc-eks.private_route_table_ids, 0)}"
  destination_cidr_block    = "${data.terraform_remote_state.vpc-shared.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.dev_eks_vpc_with_shared_vpc.id}"
}

resource "aws_route" "pub_route_table_1_dev_eks_vpc_to_shared_vpc" {
  route_table_id            = "${element(data.terraform_remote_state.vpc-eks.public_route_table_ids, 0)}"
  destination_cidr_block    = "${data.terraform_remote_state.vpc-shared.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.dev_eks_vpc_with_shared_vpc.id}"
}