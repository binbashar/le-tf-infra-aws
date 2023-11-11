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

variable "argocd" {
  type    = any
  default = {}
}

variable "argo_rollouts" {
  type    = any
  default = {}
}

variable "enable_hpa_scaling" {
  type    = bool
  default = false
}

variable "enable_vpa_scaling" {
  type    = bool
  default = false
}

variable "enable_cluster_autoscaling" {
  type    = bool
  default = false
}

variable "enable_gatus" {
  type    = bool
  default = false
}

variable "logging" {
  type    = any
  default = {}
}

variable "metrics" {
  type    = any
  default = {}
}

variable "enable_ingressmonitorcontroller" {
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
  default = true
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

variable "enable_eks_alb_logging" {
  description = "Turn EKS ALB logging on"
  type        = bool
  default     = false
}

variable "eks_alb_logging_prefix" {
  description = "Turn EKS ALB logging on"
  type        = string
  default     = ""
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
