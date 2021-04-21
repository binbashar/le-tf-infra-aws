#------------------------------------------------------------------------------
# Service Account & Permissions: Grafana KubeGraf Application
#------------------------------------------------------------------------------
resource "kubernetes_cluster_role" "grafana_kubegraf" {
  count = var.enable_grafana_dependencies ? 1 : 0

  metadata {
    name = "grafana-kubegraf"
  }

  rule {
    api_groups = [""]
    resources = [
      "namespaces",
      "pods",
      "services",
      "componentstatuses",
      "nodes",
      "events",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources = [
      "jobs",
      "cronjobs",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "daemonsets",
      "statefulsets",
    ]
    verbs = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "grafana_kubegraf" {
  count = var.enable_grafana_dependencies ? 1 : 0

  metadata {
    name = "grafana-kubegraf"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "grafana-kubegraf"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "grafana-kubegraf"
    namespace = "kube-system"
  }
}

resource "kubernetes_service_account" "grafana_kubegraf" {
  count = var.enable_grafana_dependencies ? 1 : 0

  metadata {
    name      = "grafana-kubegraf"
    namespace = "kube-system"
  }
}
