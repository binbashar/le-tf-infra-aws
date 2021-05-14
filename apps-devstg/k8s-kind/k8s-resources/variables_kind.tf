#=============================#
# Kubernetes Auth             #
#=============================#
variable "kubernetes_host" {
  type = string
}

variable "kubernetes_cluster_ca_certificate" {
  type = string
}

variable "kubernetes_client_key" {
  type = string
}

variable "kubernetes_client_certificate" {
  type = string
}

#=============================#
# Metal LB                    #
#=============================#
variable "enable_metallb" {
  type    = bool
  default = false
}
