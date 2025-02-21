locals {
  prefix      = "eks-demoapps"
  environment = replace(var.environment, "apps-", "")
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = "eks-oidc"
    Cluster     = data.terraform_remote_state.cluster.outputs.cluster_name
    Layer       = local.layer_name
  }

  tags_cluster_autoscaler  = merge(local.tags, { Subject = "cluster-autoscaler" })
  tags_certmanager         = merge(local.tags, { Subject = "certmanager" })
  tags_externaldns_private = merge(local.tags, { Subject = "externaldns-private" })
  tags_externaldns_public  = merge(local.tags, { Subject = "externaldns-public" })
  tags_aws_lb_controller   = merge(local.tags, { Subject = "aws-lb-controller" })
  tags_external_secrets    = merge(local.tags, { Subject = "external-secrets" })
  tags_grafana             = merge(local.tags, { Subject = "grafana" })
  tags_fluent_bit          = merge(local.tags, { Subject = "fluent-bit" })
  tags_argo_image_updater  = merge(local.tags, { Subject = "argo-image-updater" })
  tags_vpc_cni             = merge(local.tags, { Subject = "vpc-cni" })
  tags_ebs_csi             = merge(local.tags, { Subject = "ebs-csi" })
}
