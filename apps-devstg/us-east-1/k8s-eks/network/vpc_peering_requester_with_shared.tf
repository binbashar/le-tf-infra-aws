#
# Create a VPC Peering between (Apps DevStg) EKS VPC and Shared VPC
#
resource "aws_vpc_peering_connection" "apps_devstg_eks_vpc_with_shared_vpc" {
  count = var.vpc_shared_created && !data.terraform_remote_state.network-vpcs["network-base"].outputs.enable_tgw ? 1 : 0

  peer_owner_id = var.shared_account_id
  peer_vpc_id   = data.terraform_remote_state.shared-vpcs["shared-base"].outputs.vpc_id
  vpc_id        = module.vpc-eks.vpc_id
  auto_accept   = false

  tags = merge(map("Name", "requester-apps-devstg-eks-to-shared"), local.tags)
}

#
# Update Route Tables to go through the VPC Peering Connection
# ---
# Keep in mind that this will allow both private and public subnets traffic to
# be routed through the VPC Peering. However Network ACLs rules will block
# traffic from public subnets so, in order to have network connectivity to the
# cluster, you will have to implement other options (e.g. load balancers).
#
resource "aws_route" "priv_route_table_1_apps_devstg_eks_vpc_to_shared_vpc" {
  count = var.vpc_shared_created && !data.terraform_remote_state.network-vpcs["network-base"].outputs.enable_tgw ? 1 : 0

  route_table_id            = element(module.vpc-eks.private_route_table_ids, 0)
  destination_cidr_block    = data.terraform_remote_state.shared-vpcs["shared-base"].outputs.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.apps_devstg_eks_vpc_with_shared_vpc[0].id
}

resource "aws_route" "pub_route_table_1_apps_devstg_eks_vpc_to_shared_vpc" {
  count = var.vpc_shared_created && !data.terraform_remote_state.network-vpcs["network-base"].outputs.enable_tgw ? 1 : 0

  route_table_id            = element(module.vpc-eks.public_route_table_ids, 0)
  destination_cidr_block    = data.terraform_remote_state.shared-vpcs["shared-base"].outputs.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.apps_devstg_eks_vpc_with_shared_vpc[0].id
}
