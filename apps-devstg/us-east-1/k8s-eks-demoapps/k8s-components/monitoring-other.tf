#------------------------------------------------------------------------------
# Datadog Agent
#------------------------------------------------------------------------------
resource "helm_release" "datadog_agent" {
  count      = var.datadog_agent.enabled ? 1 : 0
  name       = "datadog"
  namespace  = kubernetes_namespace.monitoring_other[0].id
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  version    = "3.174.0"
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
#   volumes to survive any crashes. It depends on the EBS CSI driver (an EKS
#   addon, see the `addons` sublayer) to provision the volume the pod needs.
#
# ROADMAP
# - High-availability and scalability (possibly by moving away from SQLite)
# - Automate initialization steps and endpoint monitors creation.
# - Back up the volume used by Kuma and define/rehearse the restore procedure.
#------------------------------------------------------------------------------
resource "helm_release" "uptime_kuma" {
  count      = var.uptime_kuma.enabled ? 1 : 0
  name       = "uptime-kuma"
  namespace  = kubernetes_namespace.monitoring_other[0].id
  repository = "https://helm.irsigler.cloud"
  chart      = "uptime-kuma"
  version    = "4.1.0"
  values = [
    <<-EOT
      # No Ingress. Exposed at `kuma.aws.binbash.com.ar` by the `kuma` row in
      # networking-httproutes.tf, with TLS terminated at the gateway.
      ingress:
        enabled: false

      # `gp2` has to be named explicitly. It is the only StorageClass on this
      # cluster and it is NOT annotated as the default, so the chart's empty
      # `storageClassName` produced a PVC with no class at all — which never
      # binds and never errors, it just sits Pending until the helm release
      # times out. That is exactly how this failed the first time.
      volume:
        enabled: true
        storageClassName: gp2

      # Pin to the tools node group, same as every other platform component
      # here. The chart takes these as plain maps rather than the JSON strings
      # the templatefile-based charts want, so `local.tools_*` do not apply.
      nodeSelector:
        stack: tools
      tolerations:
        - key: stack
          operator: Equal
          value: tools
          effect: NoSchedule
EOT
  ]
}

#------------------------------------------------------------------------------
# Uptime Kuma exposure. See `local.private_gw_parent_refs` in locals.tf for the
# conventions every private route follows.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "uptime_kuma_route_eg" {
  count = local.private_gw_enabled && var.uptime_kuma.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "uptime-kuma"
      namespace = kubernetes_namespace.monitoring_other[0].id
    }
    spec = {
      parentRefs = local.private_gw_parent_refs
      hostnames  = ["kuma.${local.private_base_domain}"]
      rules = [{
        backendRefs = [{
          name = "uptime-kuma"
          port = 3001
        }]
      }]
    }
  }

  depends_on = [
    kubernetes_manifest.private_gateway_eg,
    helm_release.uptime_kuma,
  ]
}

moved {
  from = kubernetes_manifest.private_gw_routes["kuma"]
  to   = kubernetes_manifest.uptime_kuma_route_eg[0]
}

#------------------------------------------------------------------------------
# Gatus: Monitor HTTP, TCP, ICMP and DNS.
#
# Chart repository changed from minicloudlabs to TwiN's, which is Gatus's own
# author's. minicloudlabs had stalled: its newest chart (3.4.6) still ships
# app v5.11.0, while TwiN's 1.5.0 ships v5.34.0. Since the ask was the latest
# stable *Gatus*, the app version is what decides, and the chart version number
# going "down" from 1.1.4 to 1.5.0 is just a different repo's numbering.
#
# The switch also forced the config rewrite below: `config.services` was
# renamed `config.endpoints` upstream, so the pinned values had been invalid
# against any recent Gatus. That went unnoticed only because the component has
# been disabled.
#------------------------------------------------------------------------------
resource "helm_release" "gatus" {
  count      = var.gatus.enabled ? 1 : 0
  name       = "gatus"
  namespace  = kubernetes_namespace.monitoring_other[0].id
  repository = "https://twin.github.io/helm-charts"
  chart      = "gatus"
  version    = "1.5.0"
  values = [
    templatefile("chart-values/gatus.yaml", {
      nodeSelector = local.tools_nodeSelector,
      tolerations  = local.tools_tolerations
    })
  ]
  depends_on = [
    kubernetes_manifest.private_gateway_eg,
    helm_release.certmanager,
    helm_release.externaldns_private
  ]
}

#------------------------------------------------------------------------------
# Gatus exposure. See `local.private_gw_parent_refs` in locals.tf for the
# conventions every private route follows.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "gatus_route_eg" {
  count = local.private_gw_enabled && var.gatus.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "gatus"
      namespace = kubernetes_namespace.monitoring_other[0].id
    }
    spec = {
      parentRefs = local.private_gw_parent_refs
      hostnames  = ["gatus.${local.private_base_domain}"]
      rules = [{
        backendRefs = [{
          name = "gatus"
          port = 80
        }]
      }]
    }
  }

  depends_on = [
    kubernetes_manifest.private_gateway_eg,
    helm_release.gatus,
  ]
}

moved {
  from = kubernetes_manifest.private_gw_routes["gatus"]
  to   = kubernetes_manifest.gatus_route_eg[0]
}
