locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project
    Cluster     = data.terraform_remote_state.cluster.outputs.cluster_name
    Layer       = local.layer_name
  }
  # Add-on versions are pinned explicitly, with one deliberate exception.
  #
  # `kube-proxy` carries NO `addon_version`, so `addons.tf` falls through to
  # `data.aws_eks_addon_version`, which resolves against the cluster's own
  # Kubernetes version. Its supported skew is defined relative to the control
  # plane — a pin is a standing invitation to forget it on the next cluster
  # upgrade, which is exactly what happened: the 1.34 upgrade moved the control
  # plane and the nodes and left every add-on here at its 1.31-era version,
  # putting kube-proxy three minors behind and out of the supported skew.
  # The other three have release cycles of their own, so pinning them buys
  # reproducibility rather than costing correctness.
  addons_available = {
    coredns = {
      addon_version               = "v1.12.4-eksbuild.18"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      addon_version               = "v1.22.4-eksbuild.3"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = data.terraform_remote_state.cluster-identities.outputs.eks_addons_vpc_cni
    }
    aws-ebs-csi-driver = {
      addon_version               = "v1.63.1-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = data.terraform_remote_state.cluster-identities.outputs.eks_addons_ebs_csi
    }
  }
}
