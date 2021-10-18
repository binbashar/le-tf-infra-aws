#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
enable_private_ingress = true
#enable_public_ingress  = true

#------------------------------------------------------------------------------
# Certificate Manager
#------------------------------------------------------------------------------
enable_cert_manager = true

#------------------------------------------------------------------------------
# External DNS sync
#------------------------------------------------------------------------------
enable_private_dns_sync = true
#enable_public_dns_sync  = true

#------------------------------------------------------------------------------
# Secrets Management
#------------------------------------------------------------------------------
enable_vault = true

#------------------------------------------------------------------------------
# Auto-scaling
#------------------------------------------------------------------------------
enable_scaling = false

#------------------------------------------------------------------------------
# Monitoring
#------------------------------------------------------------------------------
enable_logging                 = false
enable_prometheus_dependencies = false

#------------------------------------------------------------------------------
# Demo Apps - ArgoCD
#------------------------------------------------------------------------------
#enable_cicd = true
#demoapps = {
#  emojivoto = false
#  gdm       = false
#  sockshop  = true
#}

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
enable_kubernetes_dashboard        = true
kubernetes_dashboard_ingress_class = "ingress-nginx-private"
kubernetes_dashboard_hosts         = "kubernetes-dashboard.us-east-2.devstg.aws.binbash.com.ar"

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
