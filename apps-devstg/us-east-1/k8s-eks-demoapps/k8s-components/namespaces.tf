resource "kubernetes_namespace" "monitoring_metrics" {
  count = var.enable_prometheus_dependencies || var.enable_prometheus_dependencies || var.enable_cluster_autoscaling || var.enable_hpa_scaling || var.enable_vpa_scaling ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-metrics"
  }
}

resource "kubernetes_namespace" "monitoring_logging" {
  count = var.logging.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-logging"
  }
}

resource "kubernetes_namespace" "monitoring_tools" {
  count = var.enable_kubernetes_dashboard || var.enable_vpa_scaling || var.cost_optimization.kube_resource_report || var.cost_optimization.cost_analyzer ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-tools"
  }
}

resource "kubernetes_namespace" "monitoring_other" {
  count = var.enable_datadog_agent || var.enable_uptime_kuma ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-other"
  }
}

resource "kubernetes_namespace" "monitoring_alerts" {
  count = var.enable_kwatch ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-alerts"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  count = var.enable_nginx_ingress_controller ? 1 : 0

  metadata {
    labels = local.labels
    name   = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "alb_ingress" {
  count = var.enable_alb_ingress_controller ? 1 : 0

  metadata {
    labels = local.labels
    name   = "alb-ingress"
  }
}

resource "kubernetes_namespace" "certmanager" {
  count = var.enable_certmanager ? 1 : 0

  metadata {
    labels = local.labels
    name   = "certmanager"
  }
}

resource "kubernetes_namespace" "externaldns" {
  count = var.enable_private_dns_sync || var.enable_public_dns_sync ? 1 : 0

  metadata {
    labels = local.labels
    name   = "externaldns"
  }
}

resource "kubernetes_namespace" "vault" {
  count = var.enable_vault ? 1 : 0

  metadata {
    labels = local.labels
    name   = "vault"
  }
}

resource "kubernetes_namespace" "external-secrets" {
  count = var.enable_external_secrets ? 1 : 0

  metadata {
    labels = local.labels
    name   = "external-secrets"
  }
}

resource "kubernetes_namespace" "argocd" {
  count = var.enable_cicd || var.enable_argocd_image_updater || var.enable_argo_rollouts ? 1 : 0

  metadata {
    labels = local.labels
    name   = "argocd"
  }
}

resource "kubernetes_namespace" "gatus" {
  count = var.enable_gatus ? 1 : 0

  metadata {
    labels = {
      environment                        = var.environment
      "goldilocks.fairwinds.com/enabled" = "true"
    }

    name = "gatus"
  }
}

resource "kubernetes_namespace" "velero" {
  count = var.enable_backups ? 1 : 0

  metadata {
    labels = local.labels
    name   = "velero"
  }
}

resource "kubernetes_namespace" "prometheus" {
  count = var.kube_prometheus_stack.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "prometheus"
  }
}

resource "kubernetes_namespace" "scaling" {
  count = var.enable_cluster_overprovisioning ? 1 : 0

  metadata {
    labels = local.labels
    name   = "scaling"
  }
}
