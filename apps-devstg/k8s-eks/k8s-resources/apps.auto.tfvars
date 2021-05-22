#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
#enable_private_ingress = true
#enable_public_ingress  = true

#------------------------------------------------------------------------------
# External DNS sync
#------------------------------------------------------------------------------
#enable_private_dns_sync = true
#enable_public_dns_sync  = true

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
#enable_kubernetes_dashboard        = true
#kubernetes_dashboard_ingress_class = "ingress-nginx-public"
#kubernetes_dashboard_hosts         = "kubernetes-dashboard.devstg.binbash.com.ar"

#------------------------------------------------------------------------------
# Demo Apps - ArgoCD
#------------------------------------------------------------------------------
#enable_cicd = true
#demoapps = {
#  emojivoto = true
#  gdm       = false
#  sockshop  = true
#}

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
