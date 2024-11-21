#------------------------------------------------------------------------------
# KWatch: Instantly monitor & detect crashes in Kubernetes.
#------------------------------------------------------------------------------
# - Could be useful if you need very basic pod monitoring capabilities.
# - But could be too noisy if you are currently getting a lot of crashes because
#   you haven't gotten around to tune your cluster or your workloads.
# - Could be helpful if you need to closely watch pods in given namespaces in
#   order to grab the events and logs of a pod that crashes when you are not
#   around to immediately check what's wrong.
#------------------------------------------------------------------------------
resource "helm_release" "kwatch" {
  count      = var.enable_kwatch ? 1 : 0
  name       = "kwatch"
  namespace  = kubernetes_namespace.monitoring_alerts[0].id
  repository = "https://kwatch.dev/charts"
  chart      = "kwatch"
  version    = "0.8.3"
  values = [
    <<-EOT
      config:
        upgrader:
          disableUpdateCheck: true

        pvcMonitor:
          enabled: true
          interval: 15
          threshold: 80

        alert:
          slack:
            webhook: TODO
EOT
  ]
}
