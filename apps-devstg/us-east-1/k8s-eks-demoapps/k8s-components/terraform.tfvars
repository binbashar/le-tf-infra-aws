#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
enable_alb_ingress_controller   = false
enable_nginx_ingress_controller = true
apps_ingress = {
  enabled = false
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
enable_external_secrets = true

#------------------------------------------------------------------------------
# Scaling
#------------------------------------------------------------------------------
enable_hpa_scaling              = false
enable_vpa_scaling              = false
enable_cluster_autoscaling      = true
enable_cluster_overprovisioning = false
enable_keda                     = true
enable_keda_http_add_on         = true

#------------------------------------------------------------------------------
# Monitoring: Logging
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Monitoring: Metrics
#------------------------------------------------------------------------------
# KubePrometheusStack
kube_prometheus_stack = {
  enabled = false
}
# (External) Prometheus dependencies
enable_prometheus_dependencies = false
enable_grafana_dependencies    = false

#------------------------------------------------------------------------------
# Monitoring: Datadog (logs, metrics, and more)
#------------------------------------------------------------------------------
enable_datadog_agent = false

#------------------------------------------------------------------------------
# Monitoring: Alerts
#------------------------------------------------------------------------------
# KWatch
enable_kwatch = false

#------------------------------------------------------------------------------
# CICD | ArgoCD
#------------------------------------------------------------------------------
enable_cicd                 = true
enable_argocd_image_updater = true
enable_argo_rollouts        = false


#------------------------------------------------------------------------------
# FinOps | Cost Optimizations Tools
#------------------------------------------------------------------------------
cost_optimization = {
  kube_resource_report = false
  cost_analyzer        = false
}

#------------------------------------------------------------------------------
# Uptime Kuma
#------------------------------------------------------------------------------
enable_uptime_kuma = false
