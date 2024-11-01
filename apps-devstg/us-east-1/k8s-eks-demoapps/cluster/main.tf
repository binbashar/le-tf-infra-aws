# -----------------------------------------------------------------------------
# Terraform EKS module wrapper
# -----------------------------------------------------------------------------
# Design Considerations:
# - Favor reusability. Do not reinvent the wheel.
# - Serve as a baseline that encapsulates our security, reliability, and
#   compliance best practices.
# - Simplify operations and maintenance by making visible only the parts that
#   change more often, while hiding complexity behind simple abstractions.
# -----------------------------------------------------------------------------
module "eks" {
  source = "../../../../terraform-modules/eks/cluster/"

  project      = var.project
  environment  = var.environment
  profile      = var.profile
  region       = var.region
  cluster_name = data.terraform_remote_state.eks-vpc.outputs.cluster_name

  vpc_id     = data.terraform_remote_state.eks-vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.eks-vpc.outputs.private_subnets
  # List of subnet CIDRs to allow outbound traffic to them
  subnet_cidrs = [data.terraform_remote_state.eks-vpc.outputs.private_subnets_cidr[0]]
  # VPC CIDR to allow inbound traffic from it (shared VPC in which VPN Server will live)
  shared_vpc_cidr_block = data.terraform_remote_state.shared-vpc.outputs.vpc_cidr_block

  # Key to encrypt selected k8s resources
  aws_kms_key_arn = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  map_roles = local.map_roles

  additional_node_groups = local.additional_node_groups

  tags = local.tags
}
