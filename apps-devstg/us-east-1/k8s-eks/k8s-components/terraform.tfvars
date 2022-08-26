#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
enable_alb_ingress_controller   = true
enable_nginx_ingress_controller = true
apps_ingress = {
  enabled = true
  # Load balancer type: internet-facing or internal
  type = "internal"
}

#------------------------------------------------------------------------------
# Certificate Manager
#------------------------------------------------------------------------------
enable_certmanager = true

#------------------------------------------------------------------------------
# External DNS sync
#------------------------------------------------------------------------------
enable_private_dns_sync = true
enable_public_dns_sync  = false

#------------------------------------------------------------------------------
# Secrets Management
#------------------------------------------------------------------------------
enable_vault            = false
enable_external_secrets = true

#------------------------------------------------------------------------------
# Scaling
#------------------------------------------------------------------------------
enable_hpa_scaling         = false
enable_vpa_scaling         = false
enable_cluster_autoscaling = true

#------------------------------------------------------------------------------
# Monitoring
#------------------------------------------------------------------------------
# logging
logging = {
  enabled = false
  # Log forwarders/processors
  # When logging is enabled fluent-bit is enabled also
  forwarders = [
    "fluentd-awses",
    "fluentd-selfhosted",
    "k8s-event-logger"
  ]
}
# metrics
enable_prometheus_dependencies = false
enable_grafana_dependencies    = false
# tools
enable_gatus = false

#------------------------------------------------------------------------------
# Kubernetes Dashboard
#------------------------------------------------------------------------------
# TODO refactor the k8s_dashboard vars declaration to a map structure similar to apps_ingress {}
enable_kubernetes_dashboard        = false
kubernetes_dashboard_ingress_class = "private-apps"
kubernetes_dashboard_hosts         = "kubernetes-dashboard.us-east-1.devstg.aws.binbash.com.ar"

#------------------------------------------------------------------------------
# IngressMonitorController
#------------------------------------------------------------------------------
enable_ingressmonitorcontroller = false
imc = {
  uptimerobot_apikey        = "APIKEY"
  uptimerobot_alertcontacts = "uptimerobot_alertcontacts"
  emojivoto_endpoint        = false
}

#------------------------------------------------------------------------------
# CICD | ArgoCD
#------------------------------------------------------------------------------
enable_cicd = true

#------------------------------------------------------------------------------
# Backups
#------------------------------------------------------------------------------
# TODO refactor the backup vars declaration into a consolidated map structure similar to apps_ingress {}
enable_backups = false
schedules = {
  cluster-backup = {
    target   = "all-cluster"
    schedule = "0 * * * *"
    ttl      = "24h"
  }
  argo-backup = {
    target             = "argcd"
    schedule           = "0 0/6 * * *"
    ttl                = "24h"
    includedNamespaces = ["argo-cd"]
  }
}
