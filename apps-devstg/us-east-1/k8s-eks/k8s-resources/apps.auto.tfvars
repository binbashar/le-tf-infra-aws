#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
enable_private_ingress = true
#enable_public_ingress  = true

#------------------------------------------------------------------------------
# Certificate Manager
#------------------------------------------------------------------------------
enable_certmanager = true

#------------------------------------------------------------------------------
# External DNS sync
#------------------------------------------------------------------------------
enable_private_dns_sync = true
#enable_public_dns_sync  = true

#------------------------------------------------------------------------------
# Secrets Management
#------------------------------------------------------------------------------
enable_vault = false

#------------------------------------------------------------------------------
# Scaling
#------------------------------------------------------------------------------
enable_hpa_scaling         = false
enable_vpa_scaling         = false
enable_cluster_autoscaling = true

#------------------------------------------------------------------------------
# Monitoring
#------------------------------------------------------------------------------
enable_logging                 = false
enable_prometheus_dependencies = false

#------------------------------------------------------------------------------
# IngressMonitorController
#------------------------------------------------------------------------------
#enable_ingressmonitorcontroller = true
#imc = {
#  uptimerobot_apikey        = "APIKEY"
#  uptimerobot_alertcontacts = "uptimerobot_alertcontacts"
#  emojivoto_endpoint        = false
#}

#------------------------------------------------------------------------------
# Kubernetes Dashboard
#------------------------------------------------------------------------------
enable_kubernetes_dashboard        = false
kubernetes_dashboard_ingress_class = "ingress-nginx-private"
kubernetes_dashboard_hosts         = "kubernetes-dashboard.us-east-1.devstg.aws.binbash.com.ar"

#------------------------------------------------------------------------------
# Demo Apps - ArgoCD
#------------------------------------------------------------------------------
enable_cicd = true
demoapps = {
  emojivoto = false
  gdm       = false
  sockshop  = true
}

#------------------------------------------------------------------------------
# Backups
#------------------------------------------------------------------------------
#enable_backups = true
#schedules = {
#  cluster-backup = {
#    target   = "all-cluster"
#    schedule = "0 * * * *"
#    ttl      = "24h"
#  }
#  argo-backup = {
#    target             = "argcd"
#    schedule           = "0 0/6 * * *"
#    ttl                = "24h"
#    includedNamespaces = ["argo-cd"]
#  }
#}
