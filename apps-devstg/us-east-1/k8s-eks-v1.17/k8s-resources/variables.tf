#=============================#
# Layer Flags                 #
#=============================#
variable "enable_private_ingress" {
  type    = bool
  default = true
}

variable "enable_public_ingress" {
  type    = bool
  default = false
}

variable "enable_private_dns_sync" {
  type    = bool
  default = true
}

variable "enable_public_dns_sync" {
  type    = bool
  default = false
}

variable "enable_certmanager" {
  type    = bool
  default = true
}

variable "enable_vault" {
  type    = bool
  default = false
}

variable "enable_cicd" {
  type    = bool
  default = false
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

variable "enable_logging_awses" {
  type    = bool
  default = false
}

variable "enable_logging_selfhosted" {
  type    = bool
  default = false
}

variable "enable_logging" {
  type    = bool
  default = false
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
  default = "ingress-nginx-private"
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
