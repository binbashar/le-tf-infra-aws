#=============================#
# Layer Flags                 #
#=============================#
variable "enable_private_ingress" {
  type    = bool
  default = false
}

variable "enable_public_ingress" {
  type    = bool
  default = false
}

variable "enable_private_dns_sync" {
  type    = bool
  default = false
}

variable "enable_public_dns_sync" {
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

variable "enable_cert_manager" {
  type    = bool
  default = false
}

variable "enable_vault" {
  type    = bool
  default = false
}

variable "enable_cicd" {
  type    = bool
  default = false
}

variable "enable_kubernetes_dashboard" {
  type    = bool
  default = false
}

variable "enable_scaling" {
  type    = bool
  default = false
}

variable "enable_gatus" {
  type    = bool
  default = false
}

variable "enable_logging" {
  type    = bool
  default = false
}

variable "logging_forwarder" {
  type    = string
  default = "fluentd"
}

variable "enable_ingressmonitorcontroller" {
  type    = bool
  default = false
}

variable "kubernetes_dashboard_ingress_class" {
  type    = string
  default = "ingress-nginx-private"
}

variable "kubernetes_dashboard_hosts" {
  type    = string
  default = "kubernetes-dashboard.devstg.aws.binbash.com.ar"
}

variable "demoapps" {
  type    = any
  default = {}
}

#==================================#
# Ingress Monitor Controller (IMC) #
#==================================#
variable "imc" {
  type    = any
  default = {}
}

#==================================#
# Fluentbit config variables       #
#==================================#
variable "elastic_host" {
  type = string

}

variable "elastic_port" {
  type = string

}

variable "elastic_user" {
  type = string

}

