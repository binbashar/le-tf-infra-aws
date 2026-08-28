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
#
# Moved off Bitnami onto the upstream kubernetes-sigs chart. The pinned
# Bitnami 5.8.4 no longer resolves — Bitnami's 2025 catalog change purged old
# versions from the public repo (they survive only under `bitnamilegacy`) and
# moved the images behind a subscription. Rather than chase a newer Bitnami
# pin into that licensing question, this uses the chart the metrics-server
# maintainers publish, which is the canonical source anyway.
#
# The values schema differs: Bitnami took `extraArgs` as a map, upstream takes
# `args` as a list appended to `defaultArgs`.
#
# NOTE: `kube_state_metrics` and `node_exporter` above have the same dead
# Bitnami pins. They are gated off (`prometheus.external.dependencies.enabled`)
# and kube-prometheus-stack ships both anyway, so they were left alone rather
# than fixed blind — see the backlog.
#
resource "helm_release" "metrics_server" {
  count      = (var.scaling.hpa.enabled || var.scaling.vpa.enabled) ? 1 : 0
  name       = "metrics-server"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.13.1"
  values = [
    templatefile("chart-values/metrics-server.yaml", {
      nodeSelector = local.tools_nodeSelector,
      tolerations  = local.tools_tolerations
    })
  ]
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
  # 52.1.0 -> 88.1.4 is 36 majors, but this is a fresh install rather than an
  # upgrade (the component had been `enabled = false`), so none of the CRD
  # migration steps in the chart's upgrade notes apply — helm installs the
  # 88.1.4 CRDs from scratch. Revisit that assumption before bumping again
  # once it is actually running: `helm upgrade` does *not* update CRDs, so a
  # future jump needs them applied by hand first.
  version = "88.1.4"
  values = [templatefile("chart-values/kube-prometheus-stack.yaml",
    {
      # Still needed after the ingress removal: Grafana's `root_url` and
      # Prometheus's `externalUrl` are built from it so their self-referential
      # links resolve. `privateIngressClass` and `platform` are gone with the
      # Ingresses.
      privateBaseDomain        = local.private_base_domain
      parentRefs               = jsonencode(local.private_gw_parent_refs)
      grafanaHost              = "grafana.${local.private_base_domain}"
      prometheusHost           = "prometheus.${local.private_base_domain}"
      alertmanagerHost         = "alertmanager.${local.private_base_domain}"
      alertmanagerEnabled      = var.prometheus.kube_stack.alertmanager.enabled
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

#--------------------------------------------------------------------------------
# kube-prometheus-stack exposure: one route per UI. See
# `local.private_gw_parent_refs` in locals.tf for the conventions every private
# route follows.
#
# The counts mirror `helm_release.kube_prometheus_stack` exactly, and
# Alertmanager's carries the extra `alertmanager.enabled` term its chart values
# are gated on — so the route can never outlive the workload and publish a
# Route53 record that 503s.
#
# Grafana's `root_url` and Prometheus's `externalUrl` in the chart values have
# to agree with the hostnames below: both build self-referential links (share
# URLs, OAuth redirects, the `generatorURL` on every alert) from them, and left
# implicit they derive from the Service name and point somewhere unreachable.

