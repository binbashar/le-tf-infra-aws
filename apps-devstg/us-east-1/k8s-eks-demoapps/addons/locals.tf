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
  # putting kube-proxy three minors behind the control plane — the edge of the
  # supported skew rather than past it, but not a place to arrive at by
  # forgetting.
  # The other three have release cycles of their own, so pinning them buys
  # reproducibility rather than costing correctness.
  # NOTE: `vpc-cni` is deliberately absent. Since terraform-aws-eks v21 hardcodes
  # `bootstrap_self_managed_addons = false`, EKS no longer installs a CNI when the
  # cluster is created -- and without one no node reaches `Ready`, so the node
  # groups in the `cluster` layer fail before this layer ever runs. The CNI is
  # therefore installed from `cluster` with `before_compute = true`; see
  # `local.bootstrap_addons` there. Declaring it here as well would fail with
  # `ResourceInUseException`.
  #
  # The CNI keeps its own IRSA identity: its role moved to the `cluster` layer
  # (`irsa-vpc-cni.tf`) so the bootstrap add-on can reference it in the same
  # apply, which is something a role in `identities` could never be. There is
  # correspondingly no `eks_addons_vpc_cni` output in that layer any more.
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
    aws-ebs-csi-driver = {
      addon_version               = "v1.63.1-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = data.terraform_remote_state.cluster-identities.outputs.eks_addons_ebs_csi
    }
  }
}
