#------------------------------------------------------------------------------
# Datadog Agent
#------------------------------------------------------------------------------
resource "helm_release" "datadog_agent" {
  count      = var.enable_datadog_agent ? 1 : 0
  name       = "datadog"
  namespace  = kubernetes_namespace.monitoring_other[0].id
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  version    = "3.1.8"
  values = [
    templatefile("chart-values/datadog.yaml", {
      site   = "[REGION].datadoghq.com"
      apiKey = "[DATADOG_API_KEY]"
    })
  ]
}

#------------------------------------------------------------------------------
# Uptime Kuma: A tool for monitoring endpoints uptime and more.
# https://github.com/louislam/uptime-kuma
#------------------------------------------------------------------------------
# IMPORTANT
# - Kuma by default uses SQLite to persist state. As a result, currently there
#   is no config-driven approach that we can use to initialize it or to define
#   the endpoints to monitor.
# - Given the above, initialization steps are required the first time you run
#   Kuma. You need to create the admin user, configure settings, and create
#   any endpoints you want to monitor through Kuma's UI.
# - Additionally, since this is a stateful application, it relies on persistent
#   volumes to survive any crashes. Version 2.14.x depends on the EBS CSI to
#   provision the volume the pod needs.
#
# ROADMAP
# - High-availability and scalability (possibly by moving away from SQLite)
# - Automate initialization steps and endpoint monitors creation.
# - Back up the volume used by Kuma and define/rehearse the restore procedure.
#------------------------------------------------------------------------------
resource "helm_release" "uptime_kuma" {
  count      = var.enable_uptime_kuma ? 1 : 0
  name       = "uptime-kuma"
  namespace  = kubernetes_namespace.monitoring_other[0].id
  repository = "https://helm.irsigler.cloud"
  chart      = "uptime-kuma"
  version    = "2.14.2"
  values     = [
    <<-EOT
      ingress:
        enabled: true
        annotations:
          kubernetes.io/tls-acme: "true"
          kubernetes.io/ingress.class: ${local.private_ingress_class}
          cert-manager.io/cluster-issuer: clusterissuer-binbash-cert-manager-clusterissuer
        hosts:
          - host: kuma.${local.platform}.${local.private_base_domain}
            paths:
              - path: /
                pathType: ImplementationSpecific
        tls:
          - secretName: kuma-tls
            hosts:
              - kuma.${local.platform}.${local.private_base_domain}
EOT
  ]
}
