#------------------------------------------------------------------------------
# Vertical Pod Autoscaler: automatic pod vertical autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "vpa" {
  count      = var.enable_vpa_scaling ? 1 : 0
  name       = "vpa"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
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
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.18.1"
  values = [
    templatefile("chart-values/cluster-autoscaler.yaml",
      {
        awsRegion   = var.region
        clusterName = data.terraform_remote_state.cluster.outputs.cluster_name
        roleArn     = data.terraform_remote_state.cluster-identities.outputs.cluster_autoscaler_role_arn
      }
    )
  ]
}
