resource "kubernetes_namespace" "monitoring_metrics" {
  count = var.prometheus.external.dependencies.enabled || var.scaling.cluster_autoscaling.enabled || var.scaling.hpa.enabled || var.scaling.vpa.enabled ? 1 : 0

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
  count = var.scaling.vpa.enabled || var.cost_optimization.kube_resource_report || var.cost_optimization.cost_analyzer ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-tools"
  }
}

resource "kubernetes_namespace" "monitoring_other" {
  count = var.datadog_agent.enabled || var.uptime_kuma.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-other"
  }
}

resource "kubernetes_namespace" "monitoring_alerts" {
  count = var.kwatch.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "monitoring-alerts"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  count = var.ingress.nginx_controller.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "alb_ingress" {
  count = var.ingress.alb_controller.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "alb-ingress"
  }
}

resource "kubernetes_namespace" "certmanager" {
  count = var.certmanager.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "certmanager"
  }
}

resource "kubernetes_namespace" "externaldns" {
  count = var.dns_sync.private.enabled || var.dns_sync.private.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "externaldns"
  }
}

resource "kubernetes_namespace" "external-secrets" {
  count = var.external_secrets.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "external-secrets"
  }
}

resource "kubernetes_namespace" "argocd" {
  count = var.argocd.enabled || var.argocd.image_updater.enabled || var.argocd.rollouts.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "argocd"
  }
}

resource "kubernetes_namespace" "prometheus" {
  count = var.prometheus.kube_stack.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "prometheus"
  }
}

resource "kubernetes_namespace" "scaling" {
  count = var.scaling.cluster_overprovisioning.enabled ? 1 : 0

  metadata {
    labels = local.labels
    name   = "scaling"
  }
}

resource "kubernetes_namespace" "keda" {
  count = var.enable_keda ? 1 : 0

  metadata {
    labels = local.labels
    name   = "keda"
  }
}
