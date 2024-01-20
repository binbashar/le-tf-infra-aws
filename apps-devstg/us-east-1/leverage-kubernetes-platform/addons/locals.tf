locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project
    Cluster     = data.terraform_remote_state.cluster.outputs.cluster_name
  }
  addons_available = {
    coredns = {
      addon_version     = "v1.10.1-eksbuild.6"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version     = "v1.28.4-minimal-eksbuild.4"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version            = "v1.16.0-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = data.terraform_remote_state.cluster-identities.outputs.eks_addons_vpc_cni
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.23.0-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = data.terraform_remote_state.cluster-identities.outputs.eks_addons_ebs_csi
    }
  }

}
