#------------------------------------------------------------------------------
# Kube State Metrics: Expose cluster metrics.
#------------------------------------------------------------------------------
resource "helm_release" "kube_state_metrics" {
  count      = var.prometheus.external.dependencies.enabled ? 1 : 0
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
  count      = var.prometheus.external.dependencies.enabled ? 1 : 0
  name       = "node-exporter"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "node-exporter"
  version    = "2.2.4"
  values     = [file("chart-values/node-exporter.yaml")]
}

#------------------------------------------------------------------------------
# Metrics Server: Expose cluster metrics.
#------------------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  count      = (var.scaling.hpa.enabled || var.scaling.vpa.enabled) ? 1 : 0
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
  count     = var.prometheus.kube_stack.enabled && var.prometheus.kube_stack.alertmanager.enabled ? 1 : 0
  provider  = aws.shared
  secret_id = "/notifications/alertmanager"
}

#
# Grafana's credentials
#
data "aws_secretsmanager_secret_version" "grafana" {
  count     = var.prometheus.kube_stack.enabled ? 1 : 0
  provider  = aws.shared
  secret_id = "/devops/monitoring/grafana/administrator"
}

resource "helm_release" "kube_prometheus_stack" {
  count      = var.prometheus.kube_stack.enabled && !var.cost_optimization.cost_analyzer ? 1 : 0
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.prometheus[0].id
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "52.1.0"
  values = [templatefile("chart-values/kube-prometheus-stack.yaml",
    {
      privateIngressClass      = local.private_ingress_class
      platform                 = local.platform
      privateBaseDomain        = local.private_base_domain
      alertmanagerSlackWebhook = var.prometheus.kube_stack.alertmanager.enabled ? jsondecode(data.aws_secretsmanager_secret_version.alertmanager_slack_webhook[0].secret_string)["webhook"] : ""
      alertmanagerSlackChannel = var.prometheus.kube_stack.alertmanager.enabled ? jsondecode(data.aws_secretsmanager_secret_version.alertmanager_slack_webhook[0].secret_string)["channel"] : ""
      grafanaUser              = jsondecode(data.aws_secretsmanager_secret_version.grafana[0].secret_string)["username"]
      grafanaPassword          = jsondecode(data.aws_secretsmanager_secret_version.grafana[0].secret_string)["password"]
      grafanaRoleArn           = data.terraform_remote_state.cluster-identities.outputs.grafana_role_arn
      nodeSelector             = local.tools_nodeSelector
      tolerations              = local.tools_tolerations
    })
  ]
}
