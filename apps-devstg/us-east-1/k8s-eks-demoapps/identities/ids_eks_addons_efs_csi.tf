#
# EKS Add-ons: EBS CSI
#
module "role_eks_addons_efs_csi" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks?ref=v5.60.0"

  create_role           = true
  role_name             = "efs-csi"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = data.terraform_remote_state.cluster.outputs.cluster_oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = local.tags
}
