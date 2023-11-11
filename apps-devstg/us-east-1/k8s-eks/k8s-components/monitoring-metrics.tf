#------------------------------------------------------------------------------
# Kube State Metrics: Expose cluster metrics.
#------------------------------------------------------------------------------
resource "helm_release" "kube_state_metrics" {
  count      = var.enable_prometheus_dependencies ? 1 : 0
  name       = "kube-state-metrics"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kube-state-metrics"
  version    = "2.2.24"
  values     = [file("chart-values/kube-state-metrics.yaml")]
}

# ------------------------------------------------------------------------------
# Node Exporter: Expose cluster node metrics.
# ------------------------------------------------------------------------------
resource "helm_release" "node_exporter" {
  count      = var.enable_prometheus_dependencies ? 1 : 0
  name       = "node-exporter"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "node-exporter"
  version    = "3.1.4"
  values     = [file("chart-values/node-exporter.yaml")]
}

#------------------------------------------------------------------------------
# Metrics Server: Expose cluster metrics.
#------------------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  count      = (var.enable_hpa_scaling || var.enable_vpa_scaling) ? 1 : 0
  name       = "metrics-server"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  version    = "5.8.4"
  values     = [file("chart-values/metrics-server.yaml")]
}

#--------------------------------------------------------------------------------
# Kube Prometheus Stack: Full Prometheus + Alertmanager + Grafana implementation.
#--------------------------------------------------------------------------------

#
# Slack webhook
#
data "aws_secretsmanager_secret_version" "alertmanager_slack_webhook" {
  count     = var.metrics.prometheus_stack.enabled ? 1 : 0
  provider  = aws.shared
  secret_id = "/notifications/alertmanager"
}

#
# Grafana's credentials
#
data "aws_secretsmanager_secret_version" "grafana" {
  count     = var.metrics.prometheus_stack.enabled ? 1 : 0
  provider  = aws.shared
  secret_id = "/grafana/administrator"
}

resource "helm_release" "kube_prometheus_stack" {
  count      = var.metrics.prometheus_stack.enabled ? 1 : 0
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://prometheus-community.github.io/helm-charts/"
  chart      = "kube-prometheus-stack"
  version    = "45.9.1"
  values = [
    templatefile("chart-values/kube-prometheus-stack.yaml", {
      ingressClass             = local.private_ingress_class,
      alertmanagerSlackWebhook = jsondecode(data.aws_secretsmanager_secret_version.alertmanager_slack_webhook[0].secret_string)["webhook"],
      alertmanagerSlackChannel = jsondecode(data.aws_secretsmanager_secret_version.alertmanager_slack_webhook[0].secret_string)["channel"],,
      alertmanagerHost         = "alertmanager.${local.environment}.${local.private_base_domain}",
      grafanaUser              = jsondecode(data.aws_secretsmanager_secret_version.grafana[0].secret_string)["username"],
      grafanaPassword          = jsondecode(data.aws_secretsmanager_secret_version.grafana[0].secret_string)["password"],,
      grafanaHost              = "grafana.${local.environment}.${local.private_base_domain}",
      grafanaRoleArn           = data.terraform_remote_state.eks-identities.outputs.grafana_role_arn,
      prometheusHost           = "prometheus.${local.environment}.${local.private_base_domain}",
      nodeSelector             = jsonencode({ stack = "monitoring" }),
      tolerations = jsonencode([
        {
          key      = "stack",
          operator = "Equal",
          value    = "monitoring",
          effect   = "NoSchedule"
        },
        {
          key      = "stack",
          operator = "Equal",
          value    = "argocd",
          effect   = "NoSchedule"
        }
      ])
    })
  ]
}
