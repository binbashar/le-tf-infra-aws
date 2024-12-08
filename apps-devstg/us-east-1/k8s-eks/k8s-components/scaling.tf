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
        clusterName = data.terraform_remote_state.eks-cluster.outputs.cluster_name
        roleArn     = data.terraform_remote_state.eks-identities.outputs.cluster_autoscaler_role_arn
      }
    )
  ]
}


#------------------------------------------------------------------------------
# KEDA: autoscaling k8s pods
#------------------------------------------------------------------------------
#
# Kubernetes, a powerful container orchestration platform, revolutionized the way
# applications are deployed and managed. However, scaling applications to meet
# fluctuating workloads can be a complex task. KEDA, a Kubernetes-based
# Event-Driven Autoscaler, provides a simple yet effective solution to
# automatically scale Kubernetes Pods based on various metrics, including
# resource utilization, custom metrics, and external events.
#------------------------------------------------------------------------------
resource "helm_release" "keda" {
  count      = var.enable_keda ? 1 : 0
  name       = "keda"
  namespace  = kubernetes_namespace.keda[0].id
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.15.0"
  values = []
}

resource "helm_release" "keda_http_add_on" {
  count      = var.enable_keda && var.enable_keda_http_add_on ? 1 : 0
  name       = "http-add-on"
  namespace  = kubernetes_namespace.keda[0].id
  repository = "https://kedacore.github.io/charts"
  chart      = "keda-add-ons-http"
  version    = "0.8.0"
  values = []
}
