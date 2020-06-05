#
# VPC Peering Connection with Dev EKS: Accepter Side
#
resource "aws_vpc_peering_connection_accepter" "with_apps_devstg_eks" {
  count = var.vpc_apps_devstg_eks_created == true ? 1 : 0

  vpc_peering_connection_id = data.terraform_remote_state.vpc-apps-dev-eks.outputs.vpc_peering_id_apps_devstg_eks_with_shared
  auto_accept               = true

  tags = merge(map("Name", "accepter-shared-from-apps-devstg-eks"), local.tags)
}

#
# Update Route Tables to go through the VPC Peering Connection
#
resource "aws_route" "priv_route_table_1_to_apps_devstg_eks_vpc" {
  count = var.vpc_apps_devstg_eks_created == true ? 1 : 0

  route_table_id            = element(module.vpc.private_route_table_ids, 0)
  destination_cidr_block    = data.terraform_remote_state.vpc-apps-dev-eks.outputs.vpc_cidr_block
  vpc_peering_connection_id = data.terraform_remote_state.vpc-apps-dev-eks.outputs.vpc_peering_id_apps_devstg_eks_with_shared
}

resource "aws_route" "pub_route_table_1_to_apps_devstg_eks_vpc" {
  count = var.vpc_apps_devstg_eks_created == true ? 1 : 0

  route_table_id            = element(module.vpc.public_route_table_ids, 0)
  destination_cidr_block    = data.terraform_remote_state.vpc-apps-dev-eks.outputs.vpc_cidr_block
  vpc_peering_connection_id = data.terraform_remote_state.vpc-apps-dev-eks.outputs.vpc_peering_id_apps_devstg_eks_with_shared
}
