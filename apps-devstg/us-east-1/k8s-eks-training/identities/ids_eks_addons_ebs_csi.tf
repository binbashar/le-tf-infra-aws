#
# EKS Add-ons: EBS CSI
#
module "role_eks_addons_ebs_csi" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.24.1"

  create_role  = true
  role_name    = "${local.environment}-${local.prefix}-eks-addons-ebs-csi"
  provider_url = replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:ebs-csi-controller-sa"
  ]

  tags = local.tags_ebs_csi
}
