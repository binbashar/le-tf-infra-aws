#=============================#
# Layer Flags                 #
#=============================#
variable "enable_nginx_ingress_controller" {
  type    = bool
  default = false
}

variable "enable_alb_ingress_controller" {
  type    = bool
  default = false
}

variable "apps_ingress" {
  type    = any
  default = {}
}

variable "enable_private_dns_sync" {
  type    = bool
  default = false
}

variable "enable_public_dns_sync" {
  type    = bool
  default = false
}

variable "enable_certmanager" {
  type    = bool
  default = false
}

variable "enable_vault" {
  type    = bool
  default = false
}

variable "enable_external_secrets" {
  type    = bool
  default = false
}

variable "enable_cicd" {
  type    = bool
  default = false
}

variable "enable_argocd_image_updater" {
  type    = bool
  default = false
}

variable "enable_argo_rollouts" {
  type    = bool
  default = false
}

variable "scaling" {
  type    = any
  default = {
    # Pods
    hpa = false
    vpa = false

    # Cluster/Nodes
    cluster_autoscaler = false
    karpenter          = false
  }
}

variable "enable_gatus" {
  type    = bool
  default = false
}

variable "logging" {
  type    = any
  default = {}
}

variable "enable_ingressmonitorcontroller" {
  type    = bool
  default = false
}

variable "enable_prometheus_stack" {
  type    = bool
  default = false
}

variable "enable_prometheus_dependencies" {
  type    = bool
  default = false
}

variable "enable_grafana_dependencies" {
  type    = bool
  default = false
}

variable "enable_kubernetes_dashboard" {
  type    = bool
  default = false
}

variable "kubernetes_dashboard_ingress_class" {
  type    = string
  default = "private-apps"
}

variable "kubernetes_dashboard_hosts" {
  type    = string
  default = "kubernetes-dashboard.devstg.aws.binbash.com.ar"
}

variable "enable_backups" {
  type    = bool
  default = false
}

#==================================#
# Ingress Monitor Controller (IMC) #
#==================================#
variable "imc" {
  type    = any
  default = {}
}

#==================================#
# Backups                          #
#==================================#
variable "schedules" {
  type    = any
  default = {}
}

#==================================#
# DataDog Agent                    #
#==================================#
variable "enable_datadog_agent" {
  type    = bool
  default = false
}

variable "cost_optimization" {
  type    = any
  default = {
    kube_resource_report = false
    cost_analyzer        = false
  }
}
