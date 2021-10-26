#
# VPC Peering: Shared DR VPC => AppsDevStg EKS DR VPC
#
module "vpc_peering_shared_dr_to_devstg_eks_dr" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  # Pass both providers so that both sides (requester and accepter) can be managed
  providers = {
    aws.this = aws
    aws.peer = aws.devstg_eks_dr
  }

  # Requester is referred to as "this", whereas accepter is the "peer"
  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.apps-devstg-vpcs["apps-devstg-k8s-eks-dr"].outputs.vpc_id

  # Specify which route tables should be updated
  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.apps-devstg-vpcs["apps-devstg-k8s-eks-dr"].outputs.public_route_table_ids,
    data.terraform_remote_state.apps-devstg-vpcs["apps-devstg-k8s-eks-dr"].outputs.private_route_table_ids
  )

  # Automatically accept the peering request on the accepter side
  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "shared-dr-to-devstg-eks-dr",
    "PeeringRequester" = "shared-dr",
    "PeeringAccepter"  = "devstg-eks-dr"
  })
}

#
# VPC Peering: Shared DR VPC => Shared VPC
#
module "vpc_peering_shared_dr_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  providers = {
    aws.this = aws
    aws.peer = aws.shared_main
  }

  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.shared-vpcs["shared-vpc"].outputs.vpc_id

  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.shared-vpcs["shared-vpc"].outputs.public_route_table_ids,
    data.terraform_remote_state.shared-vpcs["shared-vpc"].outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "shared-dr-to-shared",
    "PeeringRequester" = "shared-dr",
    "PeeringAccepter"  = "shared"
  })
}
