#
# EKS Add-ons: VPC CNI (aws-node)
#
module "role_eks_addons_vpc_cni" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.24.1"

  create_role  = true
  role_name    = "${local.environment}-${local.prefix}-eks-addons-vpc-cni"
  provider_url = replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:aws-node"
  ]

  tags = local.tags_vpc_cni
}
