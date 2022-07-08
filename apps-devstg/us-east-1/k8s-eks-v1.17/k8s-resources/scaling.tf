#------------------------------------------------------------------------------
# Vertical Pod Autoscaler: automatic pod vertical autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "vpa" {
  count      = var.enable_vpa_scaling ? 1 : 0
  name       = "vpa"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://charts.fairwinds.com/stable"
  chart      = "vpa"
  version    = "0.3.2"
  values     = [file("chart-values/vpa.yaml")]
  depends_on = [helm_release.metrics_server]
}

#------------------------------------------------------------------------------
# Cluster Autoscaler: automatic cluster nodes autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "cluster_autoscaling" {
  count      = var.enable_cluster_autoscaling ? 1 : 0
  name       = "autoscaler"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.4.0"
  values = [
    templatefile("chart-values/cluster_autoscaler.yaml",
      {
        aws_region   = var.region,
        cluster_name = data.terraform_remote_state.eks-cluster.outputs.cluster_name,
        roleArn      = "arn:aws:iam::${var.accounts.apps-devstg.id}:role/appsdevstg-cluster-autoscaler"
      }
    )
  ]
}
