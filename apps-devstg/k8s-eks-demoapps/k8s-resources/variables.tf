#
# config/backend.config
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "region_secondary" {
  description = "AWS Scondary Region for HA"
}

variable "profile" {
  type        = string
  description = "AWS Profile (required by the backend but also used for other resources)"
}

variable "bucket" {
  type        = string
  description = "AWS S3 TF State Backend Bucket"
}

variable "dynamodb_table" {
  type        = string
  description = "AWS DynamoDB TF Lock state table name"
}

variable "encrypt" {
  type        = bool
  description = "Enable AWS DynamoDB with server side encryption"
}

#
# config/base.config
#
#=============================#
# Project Variables           #
#=============================#
variable "project" {
  type        = string
  description = "Project Name"
}

variable "project_long" {
  type        = string
  description = "Project Long Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

#
# config/extra.config
#
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "root_account_id" {
  type        = string
  description = "Account: Root"
}

variable "security_account_id" {
  type        = string
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  type        = string
  description = "Account: Shared Resources"
}

variable "appsdevstg_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

variable "appsprd_account_id" {
  type        = string
  description = "Account: Prod Modules & Libs"
}

variable "vault_token" {
  type = string
}

variable "vault_address" {
  type = string
}

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

variable "enable_demoapps_sockshop" {
  type    = bool
  default = false
}

variable "enable_demoapps_sockshop_aws_integration" {
  type    = bool
  default = false
}

variable "enable_demoapps_gmd" {
  type    = bool
  default = false
}

variable "enable_demoapps_gmd_aws_integration" {
  type    = bool
  default = false
}

variable "enable_demoapps_emojivoto" {
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
